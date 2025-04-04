// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class SlideToConfirmWidget extends StatefulWidget {
//   final String label;
//   final Color backgroundColor;
//   final Color foregroundColor;
//   final double height;
//   final IconData thumbIcon;
//   final IconData endIcon;
//   final VoidCallback onConfirm;
//   final String confirmationMessage;

//   const SlideToConfirmWidget({
//     Key? key,
//     this.label = "SLIDE TO CONFIRM",
//     this.backgroundColor = const Color(0xFFEEEEEE),
//     this.foregroundColor = const Color(0xFF388E3C),
//     this.height = 56.0,
//     this.thumbIcon = Icons.check,
//     this.endIcon = Icons.arrow_forward,
//     required this.onConfirm,
//     this.confirmationMessage = "Only confirm when you have received your order",
//   }) : super(key: key);

//   @override
//   _SlideToConfirmWidgetState createState() => _SlideToConfirmWidgetState();
// }

// class _SlideToConfirmWidgetState extends State<SlideToConfirmWidget> {
//   double _sliderValue = 0.0;
//   bool _isConfirmed = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(30),
//             color: widget.backgroundColor,
//           ),
//           child: Stack(
//             children: [
//               // Slider progress indicator
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: MediaQuery.of(context).size.width * _sliderValue,
//                 height: widget.height,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   gradient: LinearGradient(
//                     colors: [
//                       widget.foregroundColor.withOpacity(0.7),
//                       widget.foregroundColor,
//                     ],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                 ),
//               ),

//               // Slider content
//               SliderTheme(
//                 data: SliderTheme.of(context).copyWith(
//                   trackHeight: widget.height,
//                   trackShape: const RoundedRectSliderTrackShape(),
//                   thumbShape: const RoundSliderThumbShape(
//                     enabledThumbRadius: 24,
//                   ),
//                   overlayShape: SliderComponentShape.noOverlay,
//                   thumbColor: Colors.white,
//                   activeTrackColor: Colors.transparent,
//                   inactiveTrackColor: Colors.transparent,
//                 ),
//                 child: Slider(
//                   value: _sliderValue,
//                   onChanged: _isConfirmed
//                       ? null
//                       : (value) {
//                           setState(() {
//                             _sliderValue = value;
//                             if (value >= 0.95) {
//                               _confirmAction();
//                             }
//                           });
//                         },
//                   onChangeEnd: _isConfirmed
//                       ? null
//                       : (value) {
//                           if (value < 0.95) {
//                             setState(() {
//                               _sliderValue = 0.0;
//                             });
//                           }
//                         },
//                 ),
//               ),

//               // Slider text
//               Center(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.only(left: 70),
//                       child: Text(
//                         "← ${widget.label}",
//                         style: TextStyle(
//                           color: _sliderValue > 0.5
//                               ? Colors.white
//                               : Colors.grey[800],
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.only(right: 20),
//                       child: Icon(
//                         widget.endIcon,
//                         color: _sliderValue > 0.5
//                             ? Colors.white
//                             : Colors.grey[800],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Thumb icon
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 100),
//                 top: 0,
//                 bottom: 0,
//                 left:
//                     (_sliderValue * (MediaQuery.of(context).size.width - 88)) +
//                         8,
//                 child: Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: Icon(
//                       widget.thumbIcon,
//                       color: widget.foregroundColor,
//                       size: 24,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         if (_sliderValue < 0.95 && !_isConfirmed)
//           Text(
//             widget.confirmationMessage,
//             style: TextStyle(
//               fontSize: 13,
//               color: Colors.grey[600],
//               fontStyle: FontStyle.italic,
//             ),
//             textAlign: TextAlign.center,
//           ),
//       ],
//     );
//   }

//   void _confirmAction() {
//     // Provide haptic feedback
//     HapticFeedback.mediumImpact();

//     // Set confirmed state
//     setState(() {
//       _isConfirmed = true;
//     });

//     // Call the onConfirm callback
//     widget.onConfirm();
//   }

//   // Reset the slider (can be called externally)
//   void reset() {
//     setState(() {
//       _sliderValue = 0.0;
//       _isConfirmed = false;
//     });
//   }
// }
