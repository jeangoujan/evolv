// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkillAdapter extends TypeAdapter<Skill> {
  @override
  final int typeId = 0;

  @override
  Skill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Skill(
      id: fields[0] as int,
      name: fields[1] as String,
      goalHours: fields[2] as double,
      totalHours: fields[3] as double,
      currentStreak: fields[4] as int,
      colorValue: fields[5] as int,
      iconCode: fields[6] as int,
      sessions: (fields[7] as List).cast<Session>(),
    );
  }

  @override
  void write(BinaryWriter writer, Skill obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.goalHours)
      ..writeByte(3)
      ..write(obj.totalHours)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.iconCode)
      ..writeByte(7)
      ..write(obj.sessions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
