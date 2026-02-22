/// Extracts the 'data' field from the backend response envelope.
///
/// Backend wraps all responses in: {success, request_id, data, error}
/// This helper checks success and returns the inner data.
dynamic unwrapEnvelope(dynamic response) {
  if (response is Map<String, dynamic>) {
    if (response['success'] == true) {
      return response['data'];
    }
    final error = response['error'];
    final message =
        error is Map ? error['message'] ?? 'Unknown error' : 'Request failed';
    throw Exception(message);
  }
  return response;
}
