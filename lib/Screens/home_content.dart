import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  final String userName;

  const HomeContent({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    // RESPONSIVO
    final titleFontSize = isDesktop ? 40.0 : (isTablet ? 36.0 : 28.0);
    final subtitleFontSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
    final iconSize = isDesktop ? 120.0 : (isTablet ? 110.0 : 90.0);
    final padding = isDesktop ? 32.0 : (isTablet ? 28.0 : 20.0);
    final centerTextSize = isDesktop ? 24.0 : (isTablet ? 22.0 : 18.0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FLEXIBILIDAD
                Flexible(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $userName!',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      Text(
                        'Bienvenido a ExoAi',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 40 : (isTablet ? 36 : 28)),

                // QUE SE EXPANDA
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: iconSize,
                            color: Colors.deepPurple[200],
                          ),
                          SizedBox(height: isDesktop ? 28 : 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth * 0.1,
                            ),
                            child: Text(
                              'Tu asistente inteligente',
                              style: TextStyle(
                                fontSize: centerTextSize,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
