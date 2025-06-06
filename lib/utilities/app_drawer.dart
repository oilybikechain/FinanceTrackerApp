import 'package:finance_tracker/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void navigateTo(page, context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, page);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Text("FINANCE  TRACKER", style: TextStyle(fontSize: 22)),
                  Container(width: 20),
                  GestureDetector(
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
                    },
                    child: Icon(Icons.brightness_6),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.home),
            title: Text("H O M E"),
            onTap: () {
              navigateTo("/homepage", context);
            },
          ),

          ListTile(
            leading: Icon(Icons.settings),
            title: Text("S E T U P"),
            onTap: () {
              navigateTo("/setuppage", context);
            },
          ),

          ListTile(
            leading: Icon(Icons.analytics_outlined),
            title: Text("S T A T I S T I C S"),
            onTap: () {
              navigateTo("/statisticspage", context);
            },
          ),
        ],
      ),
    );
  }
}
