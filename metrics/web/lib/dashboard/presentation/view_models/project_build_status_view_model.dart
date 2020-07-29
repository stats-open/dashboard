import 'package:equatable/equatable.dart';
import 'package:metrics_core/metrics_core.dart';

/// A view model that represents a status of the project build to display.
class ProjectBuildStatusViewModel extends Equatable {
  /// A status of the project build.
  final BuildStatus value;

  @override
  List<Object> get props => [value];

  /// Creates the [ProjectBuildStatusViewModel] with the given [value].
  const ProjectBuildStatusViewModel({
    this.value,
  });
}
