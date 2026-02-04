//
//  CaptureViewModelTests.swift
//  PersonalAITests
//
//  Issue #6: Unit tests for CaptureViewModel
//  Tests input validation, tag management, and thought capture flow
//

import Testing
import Foundation
@testable import PersonalAI

@Suite("CaptureViewModel Tests")
struct CaptureViewModelTests {

    // MARK: - Test Setup Helpers

    private func createTestContext() -> Context {
        Context(
            timestamp: Date(),
            location: nil,
            timeOfDay: .afternoon,
            energy: .medium,
            focusState: .deep_work,
            calendar: nil,
            activity: nil,
            weather: nil,
            stateOfMind: nil,
            energyBreakdown: nil
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with empty state")
    @MainActor
    func viewModelInitializesEmpty() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        #expect(vm.thoughtContent.isEmpty)
        #expect(vm.selectedTags.isEmpty)
        #expect(vm.voiceInputMode == false)
        #expect(vm.isCapturing == false)
        #expect(vm.context == nil)
        #expect(vm.classification == nil)
        #expect(vm.error == nil)
        #expect(vm.captureSucceeded == false)
    }

    // MARK: - Validation Tests

    @Test("isValid returns false for empty content")
    @MainActor
    func isValidReturnsFalseForEmptyContent() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = ""
        #expect(vm.isValid == false)
    }

    @Test("isValid returns false for whitespace-only content")
    @MainActor
    func isValidReturnsFalseForWhitespaceContent() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = "   \n\t   "
        #expect(vm.isValid == false)
    }

    @Test("isValid returns true for valid content")
    @MainActor
    func isValidReturnsTrueForValidContent() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = "Valid thought content"
        #expect(vm.isValid == true)
    }

    @Test("isValid returns false for content exceeding 5000 characters")
    @MainActor
    func isValidReturnsFalseForTooLongContent() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = String(repeating: "a", count: 5001)
        #expect(vm.isValid == false)
    }

    @Test("isOverLimit returns true for content exceeding 5000 characters")
    @MainActor
    func isOverLimitReturnsTrueForTooLongContent() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = String(repeating: "a", count: 5001)
        #expect(vm.isOverLimit == true)
    }

    @Test("characterCount returns correct count")
    @MainActor
    func characterCountReturnsCorrectCount() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = "Hello"
        #expect(vm.characterCount == 5)

        vm.thoughtContent = "Hello World"
        #expect(vm.characterCount == 11)
    }

    // MARK: - Tag Management Tests

    @Test("addTag adds normalized tag")
    @MainActor
    func addTagAddsNormalizedTag() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("Work")
        #expect(vm.selectedTags.contains("work"))
    }

    @Test("addTag converts spaces to hyphens")
    @MainActor
    func addTagConvertsSpacesToHyphens() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("my tag")
        #expect(vm.selectedTags.contains("my-tag"))
    }

    @Test("addTag does not add empty tags")
    @MainActor
    func addTagDoesNotAddEmptyTags() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("")
        #expect(vm.selectedTags.isEmpty)

        vm.addTag("   ")
        #expect(vm.selectedTags.isEmpty)
    }

    @Test("addTag does not add duplicate tags")
    @MainActor
    func addTagDoesNotAddDuplicates() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("work")
        vm.addTag("work")
        #expect(vm.selectedTags.count == 1)
    }

    @Test("addTag enforces 5 tag maximum")
    @MainActor
    func addTagEnforcesMaximum() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("tag1")
        vm.addTag("tag2")
        vm.addTag("tag3")
        vm.addTag("tag4")
        vm.addTag("tag5")
        vm.addTag("tag6") // Should not be added

        #expect(vm.selectedTags.count == 5)
        #expect(!vm.selectedTags.contains("tag6"))
    }

    @Test("removeTag removes the specified tag")
    @MainActor
    func removeTagRemovesTag() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("work")
        vm.addTag("personal")

        vm.removeTag("work")
        #expect(!vm.selectedTags.contains("work"))
        #expect(vm.selectedTags.contains("personal"))
    }

    // MARK: - Voice Input Mode Tests

    @Test("toggleVoiceInput toggles voice mode")
    @MainActor
    func toggleVoiceInputTogglesMode() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        #expect(vm.voiceInputMode == false)
        vm.toggleVoiceInput()
        #expect(vm.voiceInputMode == true)
        vm.toggleVoiceInput()
        #expect(vm.voiceInputMode == false)
    }

    // MARK: - Reset Form Tests

    @Test("resetForm clears all state")
    @MainActor
    func resetFormClearsAllState() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        // Set various state
        vm.thoughtContent = "Some content"
        vm.selectedTags = ["work", "personal"]
        vm.voiceInputMode = true
        vm.context = createTestContext()
        vm.contextError = "Some error"
        vm.classificationError = "Classification failed"
        vm.captureSucceeded = true

        // Reset
        vm.resetForm()

        // Verify all cleared
        #expect(vm.thoughtContent.isEmpty)
        #expect(vm.selectedTags.isEmpty)
        #expect(vm.voiceInputMode == false)
        #expect(vm.context == nil)
        #expect(vm.classification == nil)
        #expect(vm.contextError == nil)
        #expect(vm.classificationError == nil)
        #expect(vm.captureSucceeded == false)
    }

    // MARK: - Transcription Tests

    @Test("updateFromTranscription sets content and exits voice mode")
    @MainActor
    func updateFromTranscriptionSetsContentAndExitsVoiceMode() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.voiceInputMode = true
        vm.updateFromTranscription("Transcribed text")

        #expect(vm.thoughtContent == "Transcribed text")
        #expect(vm.voiceInputMode == false)
    }

    // MARK: - Similar Thoughts Tests

    @Test("hasSimilarThoughts returns false when no similar thoughts")
    @MainActor
    func hasSimilarThoughtsReturnsFalseWhenEmpty() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        #expect(vm.hasSimilarThoughts == false)
    }

    // MARK: - Loading States Tests

    @Test("Initial loading states are false")
    @MainActor
    func initialLoadingStatesAreFalse() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        #expect(vm.isCapturing == false)
        #expect(vm.isContextLoading == false)
        #expect(vm.isClassificationLoading == false)
        #expect(vm.isCheckingSimilar == false)
    }

    // MARK: - Content Edge Cases

    @Test("isValid handles exactly 5000 characters")
    @MainActor
    func isValidHandlesExactMaxLength() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = String(repeating: "a", count: 5000)
        #expect(vm.isValid == true)
        #expect(vm.isOverLimit == false)
    }

    @Test("isValid handles content with leading/trailing whitespace")
    @MainActor
    func isValidHandlesLeadingTrailingWhitespace() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.thoughtContent = "  valid content  "
        #expect(vm.isValid == true)
    }

    // MARK: - Tag Edge Cases

    @Test("addTag trims whitespace from tag")
    @MainActor
    func addTagTrimsWhitespace() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("  work  ")
        #expect(vm.selectedTags.contains("work"))
    }

    @Test("addTag handles uppercase conversion consistently")
    @MainActor
    func addTagHandlesUppercase() {
        let vm = CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )

        vm.addTag("WORK")
        #expect(vm.selectedTags.contains("work"))

        // Adding the same tag with different case should not duplicate
        vm.addTag("Work")
        #expect(vm.selectedTags.count == 1)
    }
}
