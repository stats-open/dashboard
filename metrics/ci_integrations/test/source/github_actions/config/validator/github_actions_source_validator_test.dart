// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/github_actions/models/github_token.dart';
import 'package:ci_integration/client/github_actions/models/github_token_scope.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_artifact.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_job.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config_field.dart';
import 'package:ci_integration/source/github_actions/config/validation_delegate/github_actions_source_validation_delegate.dart';
import 'package:ci_integration/source/github_actions/config/validator/github_actions_source_validator.dart';
import 'package:ci_integration/source/github_actions/strings/github_actions_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';
import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/mock/validation_result_builder_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("GithubActionsSourceValidator", () {
    const accessToken = 'accessToken';
    const repositoryOwner = 'repositoryOwner';
    const repositoryName = 'repositoryName';
    const workflowId = 'workflowId';
    const jobName = 'jobName';
    const coverageArtifactName = 'coverageArtifactName';
    const message = 'message';
    const githubToken = GithubToken(
      scopes: [GithubTokenScope.repo],
    );
    const result = FieldValidationResult.success();
    const job = WorkflowRunJob(id: 1);
    const coverageArtifact = WorkflowRunArtifact(id: 1);

    final auth = BearerAuthorization(accessToken);
    final validationDelegate = _GithubActionsSourceValidationDelegateMock();
    final validationResultBuilder = ValidationResultBuilderMock();
    final validator = GithubActionsSourceValidator(
      validationDelegate,
      validationResultBuilder,
    );
    final field = GithubActionsSourceConfigField.workflowIdentifier;
    final validationResult = ValidationResult({
      field: result,
    });

    GithubActionsSourceConfig createConfig({
      String accessToken = accessToken,
      String repositoryOwner = repositoryOwner,
      String repositoryName = repositoryName,
      String workflowIdentifier = workflowId,
      String jobName = jobName,
      String coverageArtifactName = coverageArtifactName,
    }) {
      return GithubActionsSourceConfig(
        accessToken: accessToken,
        repositoryOwner: repositoryOwner,
        repositoryName: repositoryName,
        workflowIdentifier: workflowId,
        jobName: jobName,
        coverageArtifactName: coverageArtifactName,
      );
    }

    final config = createConfig();

    PostExpectation<Future<InteractionResult<GithubToken>>> whenValidateAuth() {
      return when(validationDelegate.validateAuth(auth));
    }

    PostExpectation<Future<InteractionResult<void>>>
        whenValidateRepositoryOwner() {
      whenValidateAuth().thenSuccessWith(githubToken, message);

      return when(
        validationDelegate.validateRepositoryOwner(repositoryOwner),
      );
    }

    PostExpectation<Future<InteractionResult<void>>>
        whenValidateRepositoryName() {
      whenValidateRepositoryOwner().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        ),
      );
    }

    PostExpectation<Future<InteractionResult<void>>> whenValidateWorkflowId() {
      whenValidateRepositoryName().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateWorkflowId(workflowId),
      );
    }

    PostExpectation<Future<InteractionResult<WorkflowRunJob>>>
        whenValidateJobName() {
      whenValidateWorkflowId().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateJobName(
          workflowId: workflowId,
          jobName: jobName,
        ),
      );
    }

    PostExpectation<Future<InteractionResult<WorkflowRunArtifact>>>
        whenValidateCoverageArtifactName() {
      whenValidateJobName().thenErrorWith();
      whenValidateWorkflowId().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateCoverageArtifactName(
          workflowId: workflowId,
          coverageArtifactName: coverageArtifactName,
        ),
      );
    }

    tearDown(() {
      reset(validationDelegate);
      reset(validationResultBuilder);
    });

    test(
      "throws an ArgumentError if the given validation delegate is null",
      () {
        expect(
          () => GithubActionsSourceValidator(null, validationResultBuilder),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given validation result builder is null",
      () {
        expect(
          () => GithubActionsSourceValidator(validationDelegate, null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates a new instance with the given parameters",
      () {
        final validator = GithubActionsSourceValidator(
          validationDelegate,
          validationResultBuilder,
        );

        expect(validator.validationDelegate, equals(validationDelegate));
        expect(
          validator.validationResultBuilder,
          equals(validationResultBuilder),
        );
      },
    );

    test(
      ".validate() sets the unknown access token field validation result with the 'token not specified' additional context if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.accessToken,
            const FieldValidationResult.unknown(
              additionalContext: GithubActionsStrings.tokenNotSpecified,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'token not specified' additional context if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              additionalContext:
                  GithubActionsStrings.tokenNotSpecifiedInterruptReason,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() does not validate the access token if the access token is null",
      () async {
        final config = createConfig(accessToken: null);
        final authorization = BearerAuthorization(config.accessToken);

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateAuth(authorization),
        );
      },
    );

    test(
      ".validate() does not validate the repository owner if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateRepositoryOwner(repositoryOwner),
        );
      },
    );

    test(
      ".validate() does not validate the repository name if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verifyNever(validationDelegate.validateRepositoryName(
          repositoryOwner: repositoryOwner,
          repositoryName: repositoryName,
        ));
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() does not validate the job name if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        );
      },
    );

    test(
      ".validate() does not validate the coverage artifact name if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        );
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token is null",
      () async {
        final config = createConfig(accessToken: null);

        when(validationResultBuilder.build()).thenReturn(validationResult);

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates the access token validation to the validation delegate",
      () {
        whenValidateAuth().thenErrorWith();

        final expectedAuth = BearerAuthorization(accessToken);

        validator.validate(config);

        verify(validationDelegate.validateAuth(expectedAuth)).called(once);
      },
    );

    test(
      ".validate() sets the successful access token field validation result if the access token is valid",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();
        whenValidateAuth().thenSuccessWith(githubToken, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.accessToken,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure access token field validation result if the access token is invalid",
      () async {
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.accessToken,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'token invalid' additional context if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              additionalContext:
                  GithubActionsStrings.tokenInvalidInterruptReason,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() does not validate the repository owner if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateRepositoryOwner(repositoryOwner),
        );
      },
    );

    test(
      ".validate() does not validate the repository name if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateRepositoryName(
          repositoryOwner: repositoryOwner,
          repositoryName: repositoryName,
        ));
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() does not validate the job name if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        );
      },
    );

    test(
      ".validate() does not validate the coverage artifact name if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        );
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateAuth().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates the repository owner validation to the validation delegate",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateRepositoryOwner(repositoryOwner),
        ).called(once);
      },
    );

    test(
      ".validate() sets the successful repository owner field validation result if the repository owner is valid",
      () async {
        whenValidateRepositoryName().thenErrorWith();
        whenValidateRepositoryOwner().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryOwner,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure repository owner field validation result if the repository owner is invalid",
      () async {
        whenValidateRepositoryOwner().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryOwner,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'repository owner invalid' additional context if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              additionalContext:
                  GithubActionsStrings.repositoryOwnerInvalidInterruptReason,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() does not validate the repository name if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateRepositoryName(
          repositoryOwner: repositoryOwner,
          repositoryName: repositoryName,
        ));
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() does not validate the job name if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        );
      },
    );

    test(
      ".validate() does not validate the coverage artifact name if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        );
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the repository owner validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateRepositoryOwner().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates repository name validation to the validation delegate",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateRepositoryName(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the successful repository name field validation result if the repository name is valid",
      () async {
        whenValidateWorkflowId().thenErrorWith();
        whenValidateRepositoryName().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryName,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure repository name field validation result if the repository name is invalid",
      () async {
        whenValidateRepositoryName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryName,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'repository name invalid' additional context if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              additionalContext:
                  GithubActionsStrings.repositoryNameInvalidInterruptReason,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() does not validate the job name if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        );
      },
    );

    test(
      ".validate() does not validate the coverage artifact name if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        );
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the repository name validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateRepositoryName().thenErrorWith(null, message);

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates workflow identifier validation to the validation delegate",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateWorkflowId(workflowId),
        ).called(once);
      },
    );

    test(
      ".validate() sets the successful workflow identifier field validation result if the workflow identifier is valid",
      () async {
        whenValidateJobName().thenErrorWith();
        whenValidateCoverageArtifactName().thenErrorWith();
        whenValidateWorkflowId().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.workflowIdentifier,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure workflow identifier field validation result if the workflow identifier is invalid",
      () async {
        whenValidateWorkflowId().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.workflowIdentifier,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'workflow identifier invalid' additional context if the workflow identifier validation fails",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              additionalContext:
                  GithubActionsStrings.workflowIdInvalidInterruptReason,
            ),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() does not validate the job name if the workflow identifier validation fails",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        );
      },
    );

    test(
      ".validate() does not validate the coverage artifact name if the workflow identifier validation fails",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        );
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the workflow identifier validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateWorkflowId().thenErrorWith(null, message);

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates job name validation to the validation delegate",
      () async {
        whenValidateJobName().thenErrorWith();
        whenValidateCoverageArtifactName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateJobName(
            workflowId: workflowId,
            jobName: jobName,
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the unknown job name field validation result if the job name validation succeeds with a null interaction result",
      () async {
        whenValidateCoverageArtifactName().thenErrorWith();
        whenValidateJobName().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.jobName,
            const FieldValidationResult.unknown(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the successful job name field validation result if the job name validation succeeds with not null interaction result",
      () async {
        whenValidateCoverageArtifactName().thenErrorWith();
        whenValidateJobName().thenSuccessWith(job, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.jobName,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure job name field validation result if the job name validation fails",
      () async {
        whenValidateCoverageArtifactName().thenErrorWith();
        whenValidateJobName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.jobName,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() validates the coverage artifact name if the job name validation fails",
      () async {
        whenValidateJobName().thenErrorWith();
        whenValidateCoverageArtifactName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        ).called(once);
      },
    );

    test(
      ".validate() validates the coverage artifact name if the job name validation succeeds with a null interaction result",
      () async {
        whenValidateJobName().thenSuccessWith(null, message);
        whenValidateCoverageArtifactName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        ).called(once);
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the job name validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateJobName().thenErrorWith();
        whenValidateCoverageArtifactName().thenSuccessWith(
          coverageArtifact,
          message,
        );

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the job name validation succeeds with a null interaction result",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateJobName().thenSuccessWith(null, message);
        whenValidateCoverageArtifactName().thenSuccessWith(
          coverageArtifact,
          message,
        );

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates coverage artifact name validation to the validation delegate",
      () async {
        whenValidateCoverageArtifactName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateCoverageArtifactName(
            workflowId: workflowId,
            coverageArtifactName: coverageArtifactName,
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the unknown coverage artifact name field validation result if the coverage artifact name validation succeeds with a null interaction result",
      () async {
        whenValidateCoverageArtifactName().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.coverageArtifactName,
            const FieldValidationResult.unknown(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the successful coverage artifact name field validation result if the coverage artifact name validation succeeds with not null interaction result",
      () async {
        whenValidateCoverageArtifactName().thenSuccessWith(
          coverageArtifact,
          message,
        );

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.coverageArtifactName,
            const FieldValidationResult.success(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() sets the failure coverage artifact name field validation result if the coverage artifact name validation fails",
      () async {
        whenValidateCoverageArtifactName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.coverageArtifactName,
            const FieldValidationResult.failure(additionalContext: message),
          ),
        ).called(once);
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the coverage artifact name validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateJobName().thenSuccessWith(job, message);
        whenValidateCoverageArtifactName().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the coverage artifact name validation succeeds with a null interaction result",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateJobName().thenSuccessWith(job, message);
        whenValidateCoverageArtifactName().thenSuccessWith(
          null,
          message,
        );

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the config is valid",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateJobName().thenSuccessWith(job, message);
        whenValidateCoverageArtifactName().thenSuccessWith(
          coverageArtifact,
          message,
        );

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );
  });
}

class _GithubActionsSourceValidationDelegateMock extends Mock
    implements GithubActionsSourceValidationDelegate {}