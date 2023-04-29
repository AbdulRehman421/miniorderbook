class Area{
  int id;
  int AreaCd;
  String AreaNm;
  int SecCd;

  Area(this.id, this.AreaCd, this.AreaNm, this.SecCd);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'AreaCd': AreaCd,
      'AreaNm': AreaNm,
      'SecCd': SecCd,
    };
  }

}