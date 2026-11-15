enum Gender {
  male('MALE', 'Masculino'),
  female('FEMALE', 'Femenino'),
  nonBinary('NON_BINARY', 'No binario'),
  other('OTHER', 'Otro');

  const Gender(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Gender? fromApi(Object? value) {
    for (final gender in values) {
      if (gender.apiValue == value) {
        return gender;
      }
    }
    return null;
  }
}
