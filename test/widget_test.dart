import 'package:flutter_test/flutter_test.dart';
import 'package:africanscene/models/form_field_model.dart';
import 'package:africanscene/models/school_model.dart';
import 'package:africanscene/models/user_model.dart';

void main() {
  final krcSchool = SchoolModel(
    id: 'HpqYW7x9Tw9PW4doI89N',
    name: 'Kangemi Resource Centre (KRC)',
    location: 'Nairobi',
  );

  final recSchool = SchoolModel(
    id: 'KOZ6Ky9lr5lcHk7W6JQX',
    name: 'Raila Educational Centre (REC)',
    location: 'Nairobi',
  );

  final otherSchool = SchoolModel(
    id: 'school_other_1',
    name: 'Olympic High School',
    location: 'Nairobi',
  );

  final allSchools = [krcSchool, recSchool, otherSchool];

  group('FormType names and serialization', () {
    test('New KRC categories have expected display names and db strings', () {
      expect(FormType.krcLibraryWeekly.displayName, 'KRC Library Weekly');
      expect(FormType.krcHolidayWeekly.displayName, 'KRC Holiday Weekly');
      expect(FormType.krcItClassesWeekly.displayName, 'KRC IT Classes Weekly');

      expect(FormType.krcLibraryWeekly.toDbString(), 'krc_library_weekly');
      expect(FormType.krcHolidayWeekly.toDbString(), 'krc_holiday_weekly');
      expect(FormType.krcItClassesWeekly.toDbString(), 'krc_it_classes_weekly');
    });

    test('KRC Weekly/Termly/Annually are renamed to Kidogo Weekly/Termly/Annually', () {
      expect(FormType.krcWeekly.displayName, 'Kidogo Weekly');
      expect(FormType.krcTermly.displayName, 'Kidogo Termly');
      expect(FormType.krcAnnually.displayName, 'Kidogo Annually');

      expect(FormType.fromString('krc_weekly'), FormType.krcWeekly);
      expect(FormType.fromString('Kidogo Weekly'), FormType.krcWeekly);
      expect(FormType.fromString('krc_termly'), FormType.krcTermly);
      expect(FormType.fromString('Kidogo Termly'), FormType.krcTermly);
      expect(FormType.fromString('krc_annually'), FormType.krcAnnually);
      expect(FormType.fromString('Kidogo Annually'), FormType.krcAnnually);
    });
  });

  group('FormType visibility rules', () {
    test('Researchers and teachers assigned to KRC only see KRC/Kidogo categories and Special', () {
      final krcResearcher = UserModel(
        id: 'u1',
        email: 'krc@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        name: 'Jane Doe',
        role: UserRole.researcher,
        userType: 'researcher',
        schoolIds: [krcSchool.id],
      );

      final visible = FormType.getVisibleTypes(
        school: krcSchool,
        user: krcResearcher,
        allSchools: allSchools,
      );

      expect(
        visible.map((e) => e.displayName).toList(),
        equals([
          'KRC Library Weekly',
          'KRC Holiday Weekly',
          'KRC IT Classes Weekly',
          'Kidogo Weekly',
          'Kidogo Termly',
          'Kidogo Annually',
          'Special',
        ]),
      );
    });

    test('Researchers and teachers assigned to Raila (REC) only see REC categories and Special', () {
      final recTeacher = UserModel(
        id: 'u2',
        email: 'rec@example.com',
        firstName: 'John',
        lastName: 'Doe',
        name: 'John Doe',
        role: UserRole.teacher,
        userType: 'teacher',
        schoolIds: [recSchool.id],
      );

      final visible = FormType.getVisibleTypes(
        school: recSchool,
        user: recTeacher,
        allSchools: allSchools,
      );

      expect(
        visible.map((e) => e.displayName).toList(),
        equals([
          'REC Weekly',
          'REC Termly',
          'REC Annually',
          'Special',
        ]),
      );
    });

    test('Researchers and teachers not assigned to KRC or Raila only see Weekly, Termly, Annually, and Special', () {
      final otherTeacher = UserModel(
        id: 'u3',
        email: 'other@example.com',
        firstName: 'Mary',
        lastName: 'Smith',
        name: 'Mary Smith',
        role: UserRole.teacher,
        userType: 'teacher',
        schoolIds: [otherSchool.id],
      );

      final visible = FormType.getVisibleTypes(
        school: otherSchool,
        user: otherTeacher,
        allSchools: allSchools,
      );

      expect(
        visible.map((e) => e.displayName).toList(),
        equals([
          'Weekly',
          'Termly',
          'Annually',
          'Special',
        ]),
      );
    });

    test('Admins see all FormType values', () {
      final admin = UserModel(
        id: 'admin1',
        email: 'admin@example.com',
        firstName: 'Admin',
        lastName: 'User',
        name: 'Admin User',
        role: UserRole.superAdmin,
        userType: 'super_admin',
        schoolIds: const [],
      );

      final visible = FormType.getVisibleTypes(
        school: otherSchool,
        user: admin,
        allSchools: allSchools,
      );

      expect(visible, equals(FormType.values));
    });
  });
}
