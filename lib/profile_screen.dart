import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Info
              Row(
                children: [
                  CircleAvatar(

                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: AssetImage("assets/images/man.jpg"),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'fatman',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('+1234567890'),
                      Text('fatman@gmail.com'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileStat(title: 'Total Orders', count: '24'),
                  ProfileStat(title: 'Money Saved', count: '₹1,250'),
                  ProfileStat(title: 'Favorite Items', count: '8'),
                ],
              ),
              SizedBox(height: 16),
              Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              NotificationSwitch(title: 'Order Updates', subtitle: 'Get notified about order status'),
              NotificationSwitch(title: 'Promotions', subtitle: 'Receive offers and discounts'),
              NotificationSwitch(title: 'New Products', subtitle: 'Updates on new arrivals'),
              SizedBox(height: 16),
              // Additional options
              ProfileOption(title: 'Saved Addresses', subtitle: 'Manage delivery locations'),
              ProfileOption(title: 'Payment Methods', subtitle: 'Cards, wallets & more'),
              ProfileOption(title: 'Offers & Coupons', subtitle: 'Available discounts'),
              ProfileOption(title: 'Rate & Review', subtitle: 'Share your experience'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String title;
  final String count;

  ProfileStat({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }
}

class NotificationSwitch extends StatefulWidget {
  final String title;
  final String subtitle;

  NotificationSwitch({required this.title, required this.subtitle});

  @override
  _NotificationSwitchState createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<NotificationSwitch> {
  bool isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: isEnabled,
      onChanged: (bool value) {
        setState(() {
          isEnabled = value;
        });
      },
    );
  }
}

class ProfileOption extends StatelessWidget {
  final String title;
  final String subtitle;

  ProfileOption({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        // Handle option tap
      },
    );
  }
}