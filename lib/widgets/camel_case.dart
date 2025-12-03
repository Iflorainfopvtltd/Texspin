String toTitleCase(String input) {
  if (input.isEmpty) return input;

  // Replace underscores, hyphens, and multiple spaces with a single space
  input = input.replaceAll(RegExp(r'[_\-]+'), ' ').trim();

  // Split into words
  final words = input.split(RegExp(r'\s+'));

  // Capitalize first letter of each word
  final capitalizedWords = words
      .map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');

  return capitalizedWords;
}
