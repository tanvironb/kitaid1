
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:kitaid1/utilities/constant/texts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mycolors.Primary, // Blue page background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Header =====
                Text(
                  mytitle.loginTitle, // "Login"
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white, 
                      letterSpacing: 4),
                      
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: mysizes.spacebtwsections),

                // ===== Form =====
                // IC
                Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center, 
                   children: [
                    TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  decoration: const InputDecoration(
                    labelText: mytitle.icno,
                    // force white field
                    filled: true,
                    fillColor: Colors.white,
                    
                  
                  ),
                ),
                   ],
                ),
                
                const SizedBox(height: mysizes.spacebtwitems),

                // Password
                Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: mytitle.password,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                ],
                ),
               
                const SizedBox(height: mysizes.spacebtwsections),

                // Login button (white)
                Center(
                  child: SizedBox(
                  // width: double.infinity,
                  width:  MediaQuery.of(context).size.width * 0.3,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: handle login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: mycolors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: mysizes.btnheight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(mysizes.borderRadiusLg),
                        side: const BorderSide(color: Colors.white),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Login'),
                    
                  ),
                ),
                ),
                

                const SizedBox(height: mysizes.spacebtwsections),

                // ===== Footer =====
                Column(
                  children: [
                    const Text(
                      'Do not have account?',
                      style: TextStyle(color: Colors.white,fontSize:mysizes.fontSm ),
                    ),
                    const SizedBox(height: mysizes.sm),

                    // Signup button (white)
                    SizedBox(
                      //width: double.infinity,
                      width:  MediaQuery.of(context).size.width * 0.3,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: navigate to signup
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: mycolors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: mysizes.btnheight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(mysizes.borderRadiusLg),
                            side: const BorderSide(color: Colors.white),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
