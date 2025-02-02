/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file Copyright.txt or https://cmake.org/licensing for details.  */
#include "cmGraphVizWriter.h"

#include <cctype>
#include <iostream>
#include <memory>
#include <set>
#include <utility>

#include <cm/memory>

#include "cmGeneratedFileStream.h"
#include "cmGeneratorTarget.h"
#include "cmGlobalGenerator.h"
#include "cmLinkItem.h"
#include "cmLocalGenerator.h"
#include "cmMakefile.h"
#include "cmState.h"
#include "cmStateSnapshot.h"
#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"
#include "cmake.h"

namespace {

char const* const GRAPHVIZ_EDGE_STYLE_PUBLIC = "solid";
char const* const GRAPHVIZ_EDGE_STYLE_INTERFACE = "dashed";
char const* const GRAPHVIZ_EDGE_STYLE_PRIVATE = "dotted";

char const* const GRAPHVIZ_NODE_SHAPE_EXECUTABLE = "egg"; // egg-xecutable

// Normal libraries.
char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_STATIC = "octagon";
char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_SHARED = "doubleoctagon";
char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_MODULE = "tripleoctagon";

char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_INTERFACE = "pentagon";
char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_OBJECT = "hexagon";
char const* const GRAPHVIZ_NODE_SHAPE_LIBRARY_UNKNOWN = "septagon";

char const* const GRAPHVIZ_NODE_SHAPE_UTILITY = "box";

const char* getShapeForTarget(const cmLinkItem& item)
{
  if (item.Target == nullptr) {
    return GRAPHVIZ_NODE_SHAPE_LIBRARY_UNKNOWN;
  }

  switch (item.Target->GetType()) {
    case cmStateEnums::EXECUTABLE:
      return GRAPHVIZ_NODE_SHAPE_EXECUTABLE;
    case cmStateEnums::STATIC_LIBRARY:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_STATIC;
    case cmStateEnums::SHARED_LIBRARY:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_SHARED;
    case cmStateEnums::MODULE_LIBRARY:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_MODULE;
    case cmStateEnums::OBJECT_LIBRARY:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_OBJECT;
    case cmStateEnums::UTILITY:
      return GRAPHVIZ_NODE_SHAPE_UTILITY;
    case cmStateEnums::INTERFACE_LIBRARY:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_INTERFACE;
    case cmStateEnums::UNKNOWN_LIBRARY:
    default:
      return GRAPHVIZ_NODE_SHAPE_LIBRARY_UNKNOWN;
  }
}
}

cmGraphVizWriter::cmGraphVizWriter(std::string const& fileName,
                                   const cmGlobalGenerator* globalGenerator)
  : FileName(fileName)
  , GlobalFileStream(fileName)
  , GraphName(globalGenerator->GetSafeGlobalSetting("CMAKE_PROJECT_NAME"))
  , GraphHeader("node [\n  fontsize = \"12\"\n];")
  , GraphNodePrefix("node")
  , GlobalGenerator(globalGenerator)
  , NextNodeId(0)
  , GenerateForExecutables(true)
  , GenerateForStaticLibs(true)
  , GenerateForSharedLibs(true)
  , GenerateForModuleLibs(true)
  , GenerateForInterfaceLibs(true)
  , GenerateForObjectLibs(true)
  , GenerateForUnknownLibs(true)
  , GenerateForCustomTargets(false)
  , GenerateForExternals(true)
  , GeneratePerTarget(true)
  , GenerateDependers(true)
{
}

cmGraphVizWriter::~cmGraphVizWriter()
{
  this->WriteFooter(this->GlobalFileStream);

  for (auto& fileStream : this->PerTargetFileStreams) {
    this->WriteFooter(*fileStream.second);
  }

  for (auto& fileStream : this->TargetDependersFileStreams) {
    this->WriteFooter(*fileStream.second);
  }
}

void cmGraphVizWriter::VisitGraph(std::string const&)
{
  this->WriteHeader(GlobalFileStream, this->GraphName);
  this->WriteLegend(GlobalFileStream);
}

void cmGraphVizWriter::OnItem(cmLinkItem const& item)
{
  if (this->ItemExcluded(item)) {
    return;
  }

  NodeNames[item.AsStr()] = cmStrCat(GraphNodePrefix, NextNodeId);
  ++NextNodeId;

  this->WriteNode(this->GlobalFileStream, item);

  if (this->GeneratePerTarget) {
    this->CreateTargetFile(this->PerTargetFileStreams, item);
  }

  if (this->GenerateDependers) {
    this->CreateTargetFile(this->TargetDependersFileStreams, item,
                           ".dependers");
  }
}

void cmGraphVizWriter::CreateTargetFile(FileStreamMap& fileStreamMap,
                                        cmLinkItem const& item,
                                        std::string const& fileNameSuffix)
{
  auto const pathSafeItemName = PathSafeString(item.AsStr());
  auto const perTargetFileName =
    cmStrCat(this->FileName, '.', pathSafeItemName, fileNameSuffix);
  auto perTargetFileStream =
    cm::make_unique<cmGeneratedFileStream>(perTargetFileName);

  this->WriteHeader(*perTargetFileStream, item.AsStr());
  this->WriteNode(*perTargetFileStream, item);

  fileStreamMap.emplace(item.AsStr(), std::move(perTargetFileStream));
}

void cmGraphVizWriter::OnDirectLink(cmLinkItem const& depender,
                                    cmLinkItem const& dependee,
                                    DependencyType dt)
{
  this->VisitLink(depender, dependee, true, GetEdgeStyle(dt));
}

void cmGraphVizWriter::OnIndirectLink(cmLinkItem const& depender,
                                      cmLinkItem const& dependee)
{
  this->VisitLink(depender, dependee, false);
}

void cmGraphVizWriter::VisitLink(cmLinkItem const& depender,
                                 cmLinkItem const& dependee, bool isDirectLink,
                                 std::string const& scopeType)
{
  if (this->ItemExcluded(depender) || this->ItemExcluded(dependee)) {
    return;
  }

  if (!isDirectLink) {
    return;
  }

  this->WriteConnection(this->GlobalFileStream, depender, dependee, scopeType);

  if (this->GeneratePerTarget) {
    auto fileStream = PerTargetFileStreams[depender.AsStr()].get();
    this->WriteNode(*fileStream, dependee);
    this->WriteConnection(*fileStream, depender, dependee, scopeType);
  }

  if (this->GenerateDependers) {
    auto fileStream = TargetDependersFileStreams[dependee.AsStr()].get();
    this->WriteNode(*fileStream, depender);
    this->WriteConnection(*fileStream, depender, dependee, scopeType);
  }
}

void cmGraphVizWriter::ReadSettings(
  const std::string& settingsFileName,
  const std::string& fallbackSettingsFileName)
{
  cmake cm(cmake::RoleScript, cmState::Unknown);
  cm.SetHomeDirectory("");
  cm.SetHomeOutputDirectory("");
  cm.GetCurrentSnapshot().SetDefaultDefinitions();
  cmGlobalGenerator ggi(&cm);
  cmMakefile mf(&ggi, cm.GetCurrentSnapshot());
  std::unique_ptr<cmLocalGenerator> lg(ggi.CreateLocalGenerator(&mf));

  std::string inFileName = settingsFileName;
  if (!cmSystemTools::FileExists(inFileName)) {
    inFileName = fallbackSettingsFileName;
    if (!cmSystemTools::FileExists(inFileName)) {
      return;
    }
  }

  if (!mf.ReadListFile(inFileName)) {
    cmSystemTools::Error("Problem opening GraphViz options file: " +
                         inFileName);
    return;
  }

  std::cout << "Reading GraphViz options file: " << inFileName << std::endl;

#define __set_if_set(var, cmakeDefinition)                                    \
  do {                                                                        \
    const char* value = mf.GetDefinition(cmakeDefinition);                    \
    if (value) {                                                              \
      (var) = value;                                                          \
    }                                                                         \
  } while (false)

  __set_if_set(this->GraphName, "GRAPHVIZ_GRAPH_NAME");
  __set_if_set(this->GraphHeader, "GRAPHVIZ_GRAPH_HEADER");
  __set_if_set(this->GraphNodePrefix, "GRAPHVIZ_NODE_PREFIX");

#define __set_bool_if_set(var, cmakeDefinition)                               \
  do {                                                                        \
    const char* value = mf.GetDefinition(cmakeDefinition);                    \
    if (value) {                                                              \
      (var) = mf.IsOn(cmakeDefinition);                                       \
    }                                                                         \
  } while (false)

  __set_bool_if_set(this->GenerateForExecutables, "GRAPHVIZ_EXECUTABLES");
  __set_bool_if_set(this->GenerateForStaticLibs, "GRAPHVIZ_STATIC_LIBS");
  __set_bool_if_set(this->GenerateForSharedLibs, "GRAPHVIZ_SHARED_LIBS");
  __set_bool_if_set(this->GenerateForModuleLibs, "GRAPHVIZ_MODULE_LIBS");
  __set_bool_if_set(this->GenerateForInterfaceLibs, "GRAPHVIZ_INTERFACE_LIBS");
  __set_bool_if_set(this->GenerateForObjectLibs, "GRAPHVIZ_OBJECT_LIBS");
  __set_bool_if_set(this->GenerateForUnknownLibs, "GRAPHVIZ_UNKNOWN_LIBS");
  __set_bool_if_set(this->GenerateForCustomTargets, "GRAPHVIZ_CUSTOM_TARGETS");
  __set_bool_if_set(this->GenerateForExternals, "GRAPHVIZ_EXTERNAL_LIBS");
  __set_bool_if_set(this->GeneratePerTarget, "GRAPHVIZ_GENERATE_PER_TARGET");
  __set_bool_if_set(this->GenerateDependers, "GRAPHVIZ_GENERATE_DEPENDERS");

  std::string ignoreTargetsRegexes;
  __set_if_set(ignoreTargetsRegexes, "GRAPHVIZ_IGNORE_TARGETS");

  this->TargetsToIgnoreRegex.clear();
  if (!ignoreTargetsRegexes.empty()) {
    std::vector<std::string> ignoreTargetsRegExVector =
      cmExpandedList(ignoreTargetsRegexes);
    for (std::string const& currentRegexString : ignoreTargetsRegExVector) {
      cmsys::RegularExpression currentRegex;
      if (!currentRegex.compile(currentRegexString)) {
        std::cerr << "Could not compile bad regex \"" << currentRegexString
                  << "\"" << std::endl;
      }
      this->TargetsToIgnoreRegex.push_back(std::move(currentRegex));
    }
  }
}

void cmGraphVizWriter::Write()
{
  auto gg = this->GlobalGenerator;

  this->VisitGraph(gg->GetName());

  // We want to traverse in a determined order, such that the output is always
  // the same for a given project (this makes tests reproducible, etc.)
  std::set<cmGeneratorTarget const*, cmGeneratorTarget::StrictTargetComparison>
    sortedGeneratorTargets;

  for (cmLocalGenerator const* lg : gg->GetLocalGenerators()) {
    for (cmGeneratorTarget const* gt : lg->GetGeneratorTargets()) {
      // Reserved targets have inconsistent names across platforms (e.g. 'all'
      // vs. 'ALL_BUILD'), which can disrupt the traversal ordering.
      // We don't need or want them anyway.
      if (!cmGlobalGenerator::IsReservedTarget(gt->GetName())) {
        sortedGeneratorTargets.insert(gt);
      }
    }
  }

  for (auto const gt : sortedGeneratorTargets) {
    auto item = cmLinkItem(gt, gt->GetBacktrace());
    this->VisitItem(item);
  }
}

void cmGraphVizWriter::WriteHeader(cmGeneratedFileStream& fs,
                                   const std::string& name)
{
  auto const escapedGraphName = EscapeForDotFile(name);
  fs << "digraph \"" << escapedGraphName << "\" {" << std::endl;
  fs << this->GraphHeader << std::endl;
}

void cmGraphVizWriter::WriteFooter(cmGeneratedFileStream& fs)
{
  fs << "}" << std::endl;
}

void cmGraphVizWriter::WriteLegend(cmGeneratedFileStream& fs)
{
  // Note that the subgraph name must start with "cluster", as done here, to
  // make Graphviz layout engines do the right thing and keep the nodes
  // together.
  fs << "subgraph clusterLegend {" << std::endl;
  fs << "  label = \"Legend\";" << std::endl;
  // Set the color of the box surrounding the legend.
  fs << "  color = black;" << std::endl;
  // We use invisible edges just to enforce the layout.
  fs << "  edge [ style = invis ];" << std::endl;

  // Nodes.
  fs << "  legendNode0 [ label = \"Executable\", shape = "
     << GRAPHVIZ_NODE_SHAPE_EXECUTABLE << " ];" << std::endl;

  fs << "  legendNode1 [ label = \"Static Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_STATIC << " ];" << std::endl;
  fs << "  legendNode2 [ label = \"Shared Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_SHARED << " ];" << std::endl;
  fs << "  legendNode3 [ label = \"Module Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_MODULE << " ];" << std::endl;

  fs << "  legendNode4 [ label = \"Interface Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_INTERFACE << " ];" << std::endl;
  fs << "  legendNode5 [ label = \"Object Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_OBJECT << " ];" << std::endl;
  fs << "  legendNode6 [ label = \"Unknown Library\", shape = "
     << GRAPHVIZ_NODE_SHAPE_LIBRARY_UNKNOWN << " ];" << std::endl;

  fs << "  legendNode7 [ label = \"Custom Target\", shape = "
     << GRAPHVIZ_NODE_SHAPE_UTILITY << " ];" << std::endl;

  // Edges.
  // Some of those are dummy (invisible) edges to enforce a layout.
  fs << "  legendNode0 -> legendNode1 [ style = " << GRAPHVIZ_EDGE_STYLE_PUBLIC
     << " ];" << std::endl;
  fs << "  legendNode0 -> legendNode2 [ style = " << GRAPHVIZ_EDGE_STYLE_PUBLIC
     << " ];" << std::endl;
  fs << "  legendNode0 -> legendNode3;" << std::endl;

  fs << "  legendNode1 -> legendNode4 [ label = \"Interface\", style = "
     << GRAPHVIZ_EDGE_STYLE_INTERFACE << " ];" << std::endl;
  fs << "  legendNode2 -> legendNode5 [ label = \"Private\", style = "
     << GRAPHVIZ_EDGE_STYLE_PRIVATE << " ];" << std::endl;
  fs << "  legendNode3 -> legendNode6 [ style = " << GRAPHVIZ_EDGE_STYLE_PUBLIC
     << " ];" << std::endl;

  fs << "  legendNode0 -> legendNode7;" << std::endl;

  fs << "}" << std::endl;
}

void cmGraphVizWriter::WriteNode(cmGeneratedFileStream& fs,
                                 cmLinkItem const& item)
{
  auto const& itemName = item.AsStr();
  auto const& nodeName = this->NodeNames[itemName];

  auto const itemNameWithAliases = ItemNameWithAliases(itemName);
  auto const escapedLabel = EscapeForDotFile(itemNameWithAliases);

  fs << "    \"" << nodeName << "\" [ label = \"" << escapedLabel
     << "\", shape = " << getShapeForTarget(item) << " ];" << std::endl;
}

void cmGraphVizWriter::WriteConnection(cmGeneratedFileStream& fs,
                                       cmLinkItem const& depender,
                                       cmLinkItem const& dependee,
                                       std::string const& edgeStyle)
{
  auto const& dependerName = depender.AsStr();
  auto const& dependeeName = dependee.AsStr();

  fs << "    \"" << this->NodeNames[dependerName] << "\" -> \""
     << this->NodeNames[dependeeName] << "\" ";

  fs << edgeStyle;

  fs << " // " << dependerName << " -> " << dependeeName << std::endl;
}

bool cmGraphVizWriter::ItemExcluded(cmLinkItem const& item)
{
  auto const itemName = item.AsStr();

  if (this->ItemNameFilteredOut(itemName)) {
    return true;
  }

  if (item.Target == nullptr) {
    return !this->GenerateForExternals;
  }

  if (item.Target->GetType() == cmStateEnums::UTILITY) {
    if ((itemName.find("Nightly") == 0) ||
        (itemName.find("Continuous") == 0) ||
        (itemName.find("Experimental") == 0)) {
      return true;
    }
  }

  if (item.Target->IsImported() && !this->GenerateForExternals) {
    return true;
  }

  return !this->TargetTypeEnabled(item.Target->GetType());
}

bool cmGraphVizWriter::ItemNameFilteredOut(std::string const& itemName)
{
  if (itemName == ">") {
    // FIXME: why do we even receive such a target here?
    return true;
  }

  if (cmGlobalGenerator::IsReservedTarget(itemName)) {
    return true;
  }

  for (cmsys::RegularExpression& regEx : this->TargetsToIgnoreRegex) {
    if (regEx.is_valid()) {
      if (regEx.find(itemName)) {
        return true;
      }
    }
  }

  return false;
}

bool cmGraphVizWriter::TargetTypeEnabled(
  cmStateEnums::TargetType targetType) const
{
  switch (targetType) {
    case cmStateEnums::EXECUTABLE:
      return this->GenerateForExecutables;
    case cmStateEnums::STATIC_LIBRARY:
      return this->GenerateForStaticLibs;
    case cmStateEnums::SHARED_LIBRARY:
      return this->GenerateForSharedLibs;
    case cmStateEnums::MODULE_LIBRARY:
      return this->GenerateForModuleLibs;
    case cmStateEnums::INTERFACE_LIBRARY:
      return this->GenerateForInterfaceLibs;
    case cmStateEnums::OBJECT_LIBRARY:
      return this->GenerateForObjectLibs;
    case cmStateEnums::UNKNOWN_LIBRARY:
      return this->GenerateForUnknownLibs;
    case cmStateEnums::UTILITY:
      return this->GenerateForCustomTargets;
    case cmStateEnums::GLOBAL_TARGET:
      // Built-in targets like edit_cache, etc.
      // We don't need/want those in the dot file.
      return false;
    default:
      break;
  }
  return false;
}

std::string cmGraphVizWriter::ItemNameWithAliases(
  std::string const& itemName) const
{
  auto nameWithAliases = itemName;

  for (auto const& lg : this->GlobalGenerator->GetLocalGenerators()) {
    for (auto const& aliasTargets : lg->GetMakefile()->GetAliasTargets()) {
      if (aliasTargets.second == itemName) {
        nameWithAliases += "\\n(" + aliasTargets.first + ")";
      }
    }
  }

  return nameWithAliases;
}

std::string cmGraphVizWriter::GetEdgeStyle(DependencyType dt)
{
  std::string style;
  switch (dt) {
    case DependencyType::LinkPrivate:
      style = "[ style = " + std::string(GRAPHVIZ_EDGE_STYLE_PRIVATE) + " ]";
      break;
    case DependencyType::LinkInterface:
      style = "[ style = " + std::string(GRAPHVIZ_EDGE_STYLE_INTERFACE) + " ]";
      break;
    default:
      break;
  }
  return style;
}

std::string cmGraphVizWriter::EscapeForDotFile(std::string const& str)
{
  return cmSystemTools::EscapeChars(str.data(), "\"");
}

std::string cmGraphVizWriter::PathSafeString(std::string const& str)
{
  std::string pathSafeStr;

  // We'll only keep alphanumerical characters, plus the following ones that
  // are common, and safe on all platforms:
  auto const extra_chars = std::set<char>{ '.', '-', '_' };

  for (char c : str) {
    if (std::isalnum(c) || extra_chars.find(c) != extra_chars.cend()) {
      pathSafeStr += c;
    }
  }

  return pathSafeStr;
}
