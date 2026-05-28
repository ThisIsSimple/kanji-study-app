class TagFilter {
  final Set<String> includeAny;
  final Set<String> includeAll;
  final Set<String> exclude;

  const TagFilter({
    this.includeAny = const {},
    this.includeAll = const {},
    this.exclude = const {},
  });

  bool get isEmpty =>
      includeAny.isEmpty && includeAll.isEmpty && exclude.isEmpty;

  bool matches(Iterable<String> tags) {
    if (isEmpty) return true;

    final tagSet = tags.toSet();
    if (exclude.any(tagSet.contains)) {
      return false;
    }
    if (includeAll.isNotEmpty && !includeAll.every(tagSet.contains)) {
      return false;
    }
    if (includeAny.isNotEmpty && !includeAny.any(tagSet.contains)) {
      return false;
    }
    return true;
  }
}

extension TagFilterListExtension<T> on Iterable<T> {
  List<T> whereTags(TagFilter? filter, Iterable<String> Function(T item) tags) {
    if (filter == null || filter.isEmpty) {
      return toList();
    }
    return where((item) => filter.matches(tags(item))).toList();
  }
}
