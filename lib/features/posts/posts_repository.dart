import '../../core/network/app_http_client.dart';
import 'post_models.dart';

class PostsRepository {
  PostsRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<List<PostModel>> getPosts() async {
    final response = await _httpClient.get('/posts');
    final items = response as List<dynamic>? ?? const [];
    return items
        .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PostModel> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    final response = await _httpClient.post(
      '/posts',
      body: {
        'user_id': userId,
        'title': title,
        'body': body,
      },
    );
    return PostModel.fromJson(response as Map<String, dynamic>);
  }
}
