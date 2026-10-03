/// Resolves the display name to show for a player in historical game UI.
///
/// When the stored player is the currently authenticated user, the current
/// profile display name is preferred over the name stored with the game.
String resolveDisplayName({
  required String storedName,
  required String? storedUserId,
  required String? currentUserId,
  required String? currentDisplayName,
}) {
  if (storedUserId != null &&
      storedUserId == currentUserId &&
      currentDisplayName != null) {
    return currentDisplayName;
  }
  return storedName;
}
