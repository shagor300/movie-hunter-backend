// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_movie.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchlistMovieAdapter extends TypeAdapter<WatchlistMovie> {
  @override
  final int typeId = 2;

  @override
  WatchlistMovie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return WatchlistMovie(
      tmdbId: fields[0] as int,
      title: fields[1] as String,
      posterUrl: fields[2] as String?,
      rating: fields[3] as double,
      addedDate: fields[4] as DateTime,
      category: fields[5] as WatchlistCategory,
      userRating: fields[6] as int?,
      notes: fields[7] as String?,
      favorite: fields[8] as bool,
      releaseDate: fields[9] as String?,
      plot: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistMovie obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.tmdbId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.posterUrl)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.addedDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.userRating)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.favorite)
      ..writeByte(9)
      ..write(obj.releaseDate)
      ..writeByte(10)
      ..write(obj.plot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistMovieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WatchlistCategoryAdapter extends TypeAdapter<WatchlistCategory> {
  @override
  final int typeId = 3;

  @override
  WatchlistCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WatchlistCategory.watchlist;
      case 1:
        return WatchlistCategory.watching;
      case 2:
        return WatchlistCategory.completed;
      case 3:
        return WatchlistCategory.favorites;
      default:
        return WatchlistCategory.watchlist;
    }
  }

  @override
  void write(BinaryWriter writer, WatchlistCategory obj) {
    switch (obj) {
      case WatchlistCategory.watchlist:
        writer.writeByte(0);
        break;
      case WatchlistCategory.watching:
        writer.writeByte(1);
        break;
      case WatchlistCategory.completed:
        writer.writeByte(2);
        break;
      case WatchlistCategory.favorites:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
