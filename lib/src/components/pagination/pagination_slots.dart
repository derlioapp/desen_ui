/// The pages `DsPagination` shows, with null for a gap: up to seven slots,
/// keeping the first, the last and the neighbors of [page]. Not exported.
List<int?> paginationSlots(int page, int pageCount) {
  if (pageCount <= 0) return const [];
  if (pageCount <= 7) return [for (var i = 1; i <= pageCount; i++) i];
  if (page <= 3) return [1, 2, 3, 4, null, pageCount];
  if (page >= pageCount - 2) {
    return [1, null, for (var i = pageCount - 3; i <= pageCount; i++) i];
  }
  return [1, null, page - 1, page, page + 1, null, pageCount];
}
