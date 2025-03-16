// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthStateAdapter extends TypeAdapter<AuthState> {
  @override
  final int typeId = 1;

  @override
  AuthState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthState(
      isAuthenticating: fields[0] as bool,
      isAuthenticated: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AuthState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.isAuthenticating)
      ..writeByte(1)
      ..write(obj.isAuthenticated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
