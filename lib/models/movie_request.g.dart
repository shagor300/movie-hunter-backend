// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovieRequestAdapter extends TypeAdapter<MovieRequest> {
  @override
  final int typeId = 20;

  @override
  MovieRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovieRequest(
      id: fields[0] as String,
      movieName: fields[1] as String,
      year: fields[2] as String?,
      language: fields[3] as String?,
      quality: fields[4] as String?,
      note: fields[5] as String?,
      requestedAt: fields[6] as DateTime,
      status: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MovieRequest obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.movieName)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.quality)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.requestedAt)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
