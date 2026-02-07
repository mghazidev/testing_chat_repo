/// Unwraps API response. Backend returns { success: true, data: <payload> }.
dynamic unwrapResponse(dynamic resData) {
  if (resData is Map && resData.containsKey('data')) {
    return resData['data'];
  }
  return resData;
}
