class BoundingBox {
  final int maxClsIdx;
  final double left;
  final double top;
  final double right;
  final double bottom ;
  final double width;
  final double height;
  final double maxClsConfidence;

  BoundingBox({
    required this.maxClsIdx,
    required this.left,
    required this.top,
    required this.right ,
    required this.bottom ,
    required this.width,
    required this.height,
    required this.maxClsConfidence,
  });
}