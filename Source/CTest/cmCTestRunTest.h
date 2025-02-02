/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file Copyright.txt or https://cmake.org/licensing for details.  */
#ifndef cmCTestRunTest_h
#define cmCTestRunTest_h

#include "cmConfigure.h" // IWYU pragma: keep

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include <stddef.h>

#include "cmCTest.h"
#include "cmCTestMultiProcessHandler.h"
#include "cmCTestTestHandler.h"
#include "cmDuration.h"
#include "cmProcess.h"

/** \class cmRunTest
 * \brief represents a single test to be run
 *
 * cmRunTest contains the information related to running a single test
 */
class cmCTestRunTest
{
public:
  explicit cmCTestRunTest(cmCTestMultiProcessHandler& multiHandler);

  void SetNumberOfRuns(int n)
  {
    this->NumberOfRunsLeft = n;
    this->NumberOfRunsTotal = n;
  }

  void SetRerunMode(cmCTest::Rerun r) { this->RerunMode = r; }
  void SetTestProperties(cmCTestTestHandler::cmCTestTestProperties* prop)
  {
    this->TestProperties = prop;
  }

  cmCTestTestHandler::cmCTestTestProperties* GetTestProperties()
  {
    return this->TestProperties;
  }

  void SetIndex(int i) { this->Index = i; }

  int GetIndex() { return this->Index; }

  void AddFailedDependency(const std::string& failedTest)
  {
    this->FailedDependencies.insert(failedTest);
  }

  std::string GetProcessOutput() { return this->ProcessOutput; }

  cmCTestTestHandler::cmCTestTestResult GetTestResults()
  {
    return this->TestResult;
  }

  // Read and store output.  Returns true if it must be called again.
  void CheckOutput(std::string const& line);

  // launch the test process, return whether it started correctly
  bool StartTest(size_t completed, size_t total);
  // capture and report the test results
  bool EndTest(size_t completed, size_t total, bool started);
  // Called by ctest -N to log the command string
  void ComputeArguments();

  void ComputeWeightedCost();

  bool StartAgain(size_t completed);

  void StartFailure(std::string const& output);

  cmCTest* GetCTest() const { return this->CTest; }

  std::string& GetActualCommand() { return this->ActualCommand; }

  const std::vector<std::string>& GetArguments() { return this->Arguments; }

  void FinalizeTest();

  bool TimedOutForStopTime() const { return this->TimeoutIsForStopTime; }

  void SetUseAllocatedHardware(bool use) { this->UseAllocatedHardware = use; }
  void SetAllocatedHardware(
    const std::vector<
      std::map<std::string,
               std::vector<cmCTestMultiProcessHandler::HardwareAllocation>>>&
      hardware)
  {
    this->AllocatedHardware = hardware;
  }

private:
  bool NeedsToRerun();
  void DartProcessing();
  void ExeNotFound(std::string exe);
  bool ForkProcess(cmDuration testTimeOut, bool explicitTimeout,
                   std::vector<std::string>* environment,
                   std::vector<size_t>* affinity);
  void WriteLogOutputTop(size_t completed, size_t total);
  // Run post processing of the process output for MemCheck
  void MemCheckPostProcess();

  void SetupHardwareEnvironment();

  // Returns "completed/total Test #Index: "
  std::string GetTestPrefix(size_t completed, size_t total) const;

  cmCTestTestHandler::cmCTestTestProperties* TestProperties;
  bool TimeoutIsForStopTime = false;
  // Pointer back to the "parent"; the handler that invoked this test run
  cmCTestTestHandler* TestHandler;
  cmCTest* CTest;
  std::unique_ptr<cmProcess> TestProcess;
  std::string ProcessOutput;
  // The test results
  cmCTestTestHandler::cmCTestTestResult TestResult;
  cmCTestMultiProcessHandler& MultiTestHandler;
  int Index;
  std::set<std::string> FailedDependencies;
  std::string StartTime;
  std::string ActualCommand;
  std::vector<std::string> Arguments;
  bool UseAllocatedHardware = false;
  std::vector<std::map<
    std::string, std::vector<cmCTestMultiProcessHandler::HardwareAllocation>>>
    AllocatedHardware;
  cmCTest::Rerun RerunMode = cmCTest::Rerun::Never;
  int NumberOfRunsLeft = 1;  // default to 1 run of the test
  int NumberOfRunsTotal = 1; // default to 1 run of the test
  bool RunAgain = false;     // default to not having to run again
  size_t TotalNumberOfTests;
};

inline int getNumWidth(size_t n)
{
  int w = 1;
  while (n >= 10) {
    n /= 10;
    ++w;
  }
  return w;
}

#endif
