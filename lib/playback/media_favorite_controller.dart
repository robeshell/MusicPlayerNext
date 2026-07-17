import 'package:flutter/foundation.dart';

import '../domain/library_models.dart';

abstract interface class MediaFavoriteController implements Listenable {
  bool isFavorite(String trackId);

  Future<void> toggleFavorite(Track track);
}
