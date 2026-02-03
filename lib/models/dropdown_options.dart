class DropdownOptions {
  final List<String> departments;
  final List<String> destinations;

  DropdownOptions({
    required this.departments,
    required this.destinations,
  });

  factory DropdownOptions.empty() {
    return DropdownOptions(
      departments: [],
      destinations: [],
    );
  }
}
