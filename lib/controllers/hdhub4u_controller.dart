import 'package:get/get.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class HDHub4uController extends GetxController {
  final ApiService _apiService = ApiService();

  var movies = <Movie>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMovies();
  }

  Future<void> loadMovies() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final results = await _apiService.getLatestFromHDHub4u(maxResults: 50);

      movies.value = results.map((json) => Movie.fromJson(json)).toList();

      if (movies.isEmpty) {
        hasError.value = true;
        errorMessage.value =
            'No movies returned from server. The backend may still be deploying.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadMovies();
  }
}
