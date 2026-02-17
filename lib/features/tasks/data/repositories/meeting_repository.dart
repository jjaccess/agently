import '../../domain/meeting.dart';

abstract class MeetingRepository {
  Future<List<Meeting>> getMeetings();
  Future<void> saveMeeting(Meeting meeting);
  Future<void> updateMeeting(Meeting meeting);
  Future<void> deleteMeeting(String id);
}
