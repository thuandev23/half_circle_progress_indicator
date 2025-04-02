import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flip Color Example',
      home: FlipColorPage(),
    );
  }
}

class FlipColorPage extends StatefulWidget {
  const FlipColorPage({super.key});

  @override
  State<FlipColorPage> createState() => _FlipColorPageState();
}

class _FlipColorPageState extends State<FlipColorPage> {
  final _colorController = StreamController<Color>(); // Stream để phát màu sắc
  late Timer _timer; // Biến Timer để thay đổi màu định kỳ
  int _currentColorIndex = 0;

  final List<Color> _colors = [Colors.black87, Colors.white70];

  @override
  void initState() {
    super.initState();
    // Thiết lập timer thay đổi màu sắc mỗi giây
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _currentColorIndex = (_currentColorIndex + 1) % _colors.length;
      _colorController.sink.add(
        _colors[_currentColorIndex],
      ); // Phát màu mới vào stream
    });
  }

  @override
  void dispose() {
    _colorController.close(); // Đóng stream khi không sử dụng nữa
    _timer.cancel(); // Hủy bỏ timer khi không cần nữa
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Flip Color Example',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: StreamBuilder<Color>(
          stream: _colorController.stream, // Lắng nghe stream màu sắc
          builder: (context, snapshot) {
            final currentColor = snapshot.data ?? _colors[0];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Image.asset(
                    'assets/image.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  FlipColorWidget(color: currentColor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FlipColorWidget extends StatefulWidget {
  const FlipColorWidget({required this.color, super.key});

  final Color color;

  @override
  State<FlipColorWidget> createState() => _FlipColorWidgetState();
}

class _FlipColorWidgetState extends State<FlipColorWidget>
    with TickerProviderStateMixin {
  late AnimationController
  _animationTopHalfController; // Controller cho nửa trên
  late AnimationController _animationBottomHalfController; // Controller cho nửa dưới

  late Animation<double> _animationTopHalf; // Hoạt ảnh nửa trên
  late Animation<double> _animationBottomHalf; // Hoạt ảnh nửa dưới

  late Color _colorWhenAnimationEnds; // Màu sắc khi hoạt ảnh kết thúc
  bool _animationEnds = true; // Cờ xác định xem hoạt ảnh đã kết thúc chưa
  double _rotationAngle = 0.0; // Góc quay để tạo hiệu ứng lật

  @override
  void initState() {
    super.initState();

    // Khởi tạo các AnimationController
    _animationTopHalfController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() => setState(() => {}));

    _animationBottomHalfController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() => setState(() => {}));

    // Cài đặt Tween cho các nửa của hoạt ảnh
    _animationTopHalf = Tween<double>(
      begin: -(math.pi * 2),
      end: -(math.pi * 1.5),
    ).animate(_animationTopHalfController);
    _animationBottomHalf = Tween<double>(
      begin: -(math.pi * 1.5),
      end: -math.pi,
    ).animate(_animationBottomHalfController);

    _colorWhenAnimationEnds = widget.color;
  }

  // Hàm khởi động hoạt ảnh
  Future<void> initAnimation() async {
    setState(() => _animationEnds = false); // Đặt lại trạng thái hoạt ảnh

    unawaited(
      _animationTopHalfController.forward(),
    ); // Bắt đầu hoạt ảnh nửa trên

    if (_animationTopHalfController.isCompleted) {
      unawaited(
        _animationBottomHalfController.forward(),
      ); // Bắt đầu hoạt ảnh nửa dưới
    }

    // Khi hoạt ảnh hoàn thành, thay đổi màu sắc và reset hoạt ảnh
    if (_animationTopHalfController.isCompleted &&
        _animationBottomHalfController.isCompleted) {
      setState(() => _colorWhenAnimationEnds = widget.color);
      setState(() => _animationEnds = true);
      setState(() => _rotationAngle += math.pi / 2);
      _animationTopHalfController.reset();
      _animationBottomHalfController.reset();
    }
  }

  @override
  void dispose() {
    _animationTopHalfController.dispose(); // Hủy bỏ controller nửa trên
    _animationBottomHalfController.dispose(); // Hủy bỏ controller nửa dưới
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_colorWhenAnimationEnds != widget.color) {
      initAnimation(); // Khởi động lại hoạt ảnh nếu màu sắc thay đổi
    }

    return Transform.rotate(
      angle: _rotationAngle, // Quay đối tượng để tạo hiệu ứng lật
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: ColorContainer(
                    color: widget.color,
                  ), // Nửa trên của màu sắc
                ),
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: AnimatedBuilder(
                    animation:
                        _animationTopHalf, // Tạo hiệu ứng hoạt ảnh cho nửa trên
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(_animationTopHalf.value),
                        child: child,
                      );
                    },
                    child: ColorContainer(
                      color:
                          _animationEnds
                              ? widget.color
                              : _colorWhenAnimationEnds, // Màu sắc khi hoạt ảnh kết thúc
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRect(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 0.5,
                  child: ColorContainer(
                    color:
                        _animationEnds
                            ? widget.color
                            : _colorWhenAnimationEnds, // Nửa dưới của màu sắc
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 0.5,
                  child: AnimatedBuilder(
                    animation:
                        _animationBottomHalf, // Tạo hiệu ứng hoạt ảnh cho nửa dưới
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(_animationBottomHalf.value),
                        child: child,
                      );
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationX(math.pi), // Lật nửa dưới
                      child: ColorContainer(color: widget.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColorContainer extends StatelessWidget {
  const ColorContainer({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
