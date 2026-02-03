class TripRecord {
  final DateTime useDate;
  final String department;
  final String name;
  final int? beforeOdometer;
  final int? afterOdometer;
  final int? usedDistance;
  final int? commuteDistance;
  final int? businessDistance;
  final String? destination;
  final int? paymentAmount;
  final int? fuelCost;
  final int? repairCost;
  final String? other;
  final String? notes;

  TripRecord({
    required this.useDate,
    required this.department,
    required this.name,
    this.beforeOdometer,
    this.afterOdometer,
    this.usedDistance,
    this.commuteDistance,
    this.businessDistance,
    this.destination,
    this.paymentAmount,
    this.fuelCost,
    this.repairCost,
    this.other,
    this.notes,
  });

  // Google Sheets에 추가할 때 사용하는 리스트 형식
  List<dynamic> toSheetRow() {
    return [
      _formatDate(useDate), // A열: 사용일자
      department, // B열: 부서
      name, // C열: 성명
      beforeOdometer ?? '', // D열: 주행 전 주행거리
      afterOdometer ?? '', // E열: 주행 후 주행거리
      usedDistance ?? '', // F열: 사용거리
      commuteDistance ?? '', // G열: 출.퇴근용
      businessDistance ?? '', // H열: 일반업무용
      destination ?? '', // I열: 목적지
      paymentAmount ?? '', // J열: 결제금액
      fuelCost ?? '', // K열: 유류비
      repairCost ?? '', // L열: 수선비
      other ?? '', // M열: 기타
      notes ?? '', // N열: 비고
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.year}. ${date.month}. ${date.day}';
  }
}
