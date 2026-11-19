import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension RoleMapping on Role {
  String toDto() => switch (this) {
    Role.adopter => UserDto.adopter,
    Role.volunteer => UserDto.volunteer,
    Role.seniorVolunteer => UserDto.seniorVolunteer,
    Role.veterinarian => UserDto.veterinarian,
    Role.coordinator => UserDto.coordinator,
  };
}

Role roleFromDto(String value) => switch (value) {
  UserDto.adopter => Role.adopter,
  UserDto.volunteer => Role.volunteer,
  UserDto.seniorVolunteer => Role.seniorVolunteer,
  UserDto.veterinarian => Role.veterinarian,
  UserDto.coordinator => Role.coordinator,
  _ => throw FormatException('Unknown role', value),
};

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.toDto());
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(id: UserId(id), name: name, role: roleFromDto(role));
}
