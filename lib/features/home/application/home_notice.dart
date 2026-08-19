enum HomeNotice { alreadySatisfied, alreadyClean, restNotNeeded, needsRest }

class HomeActionResult {
  const HomeActionResult({required this.accepted, this.notice});

  const HomeActionResult.accepted() : accepted = true, notice = null;

  const HomeActionResult.rejected([this.notice]) : accepted = false;

  final bool accepted;
  final HomeNotice? notice;
}
