// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homepage_movie.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomepageMovieAdapter extends TypeAdapter<HomepageMovie> {
  @override
  final int typeId = 7;

  @override
  HomepageMovie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomepageMovie(
      tmdbId: fields[0] as int,
      title: fields[1] as String,
      posterUrl: fields[2] as String?,
      backdropUrl: fields[3] as String?,
      rating: fields[4] as double,
      overview: fields[5] as String,
      releaseDate: fields[6] as String?,
      year: fields[7] as String?,
      sourceUrl: fields[8] as String,
      source: fields[9] as String,
      addedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HomepageMovie obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.tmdbId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.posterUrl)
      ..writeByte(3)
      ..write(obj.backdropUrl)
      ..writeByte(4)
      ..write(obj.rating)
      ..writeByte(5)
      ..write(obj.overview)
      ..writeByte(6)
      ..write(obj.releaseDate)
      ..writeByte(7)
      ..write(obj.year)
      ..writeByte(8)
      ..write(obj.sourceUrl)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomepageMovieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
