# 📌 Changelog: LINC Frontend (Flutter)

This document tracks all major features, improvements, and fixes in the Flutter application.

---

## 🚀 **0.4.0 – Profile & User Management**

### ✨ Features

- Added **Profile Page UI** to display user info (name, email, phone) and saved addresses.
- Integrated **CustomerProvider** to fetch and display real user/address data
  from `GET /api/users/me`.
- Implemented **Logout button** with confirmation dialog: clears all user
  state (`CustomerProvider`, `LoginProvider`) and navigates to `LoginPage`.
- Added **Edit Profile dialog** to update user name and phone via `updateUserProfile` API.
- Added **Delete Address option** with confirmation dialog (calls `deleteAddress` API).
- Added **Add New Address button** (UI only, navigates to placeholder).

### 🛠 API & State

- Created `lib/api/user_api.dart` for user-related API
  calls (`getMyProfile`, `addAddress`, `updateAddress`, `deleteAddress`, `updateUserProfile`).
- Updated **CustomerProvider** with methods to call `UserApi` for profile & address management.

### 🐞 Fixes

- Fixed **Null check operator crash** on `HomePage` during app load.
- Corrected `userMdl.dart` and `addressMdl.dart` with proper `fromJson` constructors and missing
  fields (e.g., phone).

---

## 🛒 **0.3.0 – Checkout & Order History**

### ✨ Features

- Added **Checkout Page UI**: cart summary, price details (total, discount, delivery), selected
  address & payment method (static UI).
- Implemented **Place Order button** → calls `placeOrder` in `CustomerProvider`.
- Integrated **Success Dialog** on successful order → navigates back to Home.
- Integrated **Error Dialog** on failure → displays backend error.
- Added **Orders Page UI** to list past orders.
- Implemented `fetchMyOrders` in `CustomerProvider` to load order history.
- Added **loading, error, and empty states** to `OrdersPage`.

### 🛠 API & State

- Created `lib/api/order_api.dart` with `createOrder (POST)` and `getMyOrders (POST)`.
- Updated **CustomerProvider** with `placeOrder` and `fetchMyOrders` logic.
- Added `lib/customer/models/orderMdl.dart` with `fromJson` constructor.

---

## 🛍 **0.2.0 – Product & Cart Flow**

### ✨ Features

- Added **CategoryProductsPage** to display products by category.
- Added **Search Page UI** with search bar, recent searches, and “Trending Now” list.
- Added **Product Detail Page** with image, price, rating, and description.
- Implemented **Quantity Selector** + **Add to Cart button**.
- Added **Cart Page UI** with cart items and summary.
- Implemented **quantity controls (+/-)** and **Remove Item button**, synced with backend.

### 🛠 API & State

- Created `lib/api/cart_api.dart` for cart operations (`fetch`, `add`, `update`, `remove`, `clear`).
- Updated **CustomerProvider** to use `CartApi` with loading/error handling and optimistic UI
  updates.
- Updated **ProductCard** → navigates to `ProductDetailPage` with `productId`.
- Updated **HomePage search bar** → navigates to `SearchPage`.

### 📦 Models

- Created `lib/customer/models/cart_itemMdl.dart`.
- Updated `productMdl.dart` with `fromJson` constructor.

### 🔄 Refactor

- Extracted **ProductCard** into a reusable widget file.

---

## 🔑 **0.1.0 – Authentication & Core Setup**

### ✨ Features

- Added **SplashScreen**, **LoginPage**, and **SignUpPage** UIs.
- Implemented **dual-role toggle** (Customer/Seller) on Login & Signup.
- Added **Name field** to `SignUpPage` (required by backend).
- Created **CustomerLayout** and **SellerLayout** with bottom navigation bars.

### 🛠 API & State

- Created **core ApiClient** with support for `POST`, `GET`, `PUT`, `DELETE`, JWT storage, and
  local/live URL switching.
- Added `lib/api/auth_api.dart` for login & registration.
- Created **LoginProvider** and **SignupProvider** for auth state.
- Implemented **role validation** in `LoginProvider`.

### ⚠️ Error Handling

- Added reusable **ErrorDialog** and **SuccessDialog** widgets.
- Integrated dialogs into Login & Signup for user-friendly feedback.

### 🐞 Fixes

- Implemented **case-insensitive email handling** in `auth_api.dart`.
- Fixed multiple **PlatformException** and **Null check errors** during setup.

🚀 [2025-11-12] – Cross-Stack Debugging & Features

This update includes major bug fixes and new features for the seller dashboard.

✨ Features

Seller CSV Template Download: Implemented a "Download Template" feature in product_upload_page.dart.
This function generates a sample CSV file with correct headers (title, price, stock, etc.) and saves
it to the user's device (Downloads folder on Android, Files app on iOS) to guide sellers in
formatting their bulk uploads.

🐛 Bug Fixes

Logout Crash Fixed: Resolved a critical crash (Looking up a deactivated widget's ancestor is unsafe)
in logout_button.dart. The fix caches the Navigator and LoginProvider in local variables before the
Future.delayed call, preventing the app from using a deactivated BuildContext.

Android Download Permissions Fixed: Corrected the template download feature on modern Android
devices (Android 10+). The app now uses device_info_plus to check the Android version and only
requests Permission.storage on Android 9 or older, as it's not required on newer versions. This
resolves the "storage permission is required" error.

Download Path Corrected: Replaced the deprecated getExternalStoragePublicDirectory with the modern
getDownloadsDirectory() (Android) and getApplicationDocumentsDirectory() (iOS) in
product_upload_page.dart, fixing a native error.

File Upload Page Syntax: Corrected the entire product_upload_page.dart file structure, fixing syntax
errors where functions were incorrectly nested.

⚙️ Improvements

Smarter Category Filtering: Refactored the customer_provider.dart to create a new
availableCategories list. The customer-facing app now filters the "Shop by Category" and "All
Categories" pages to only display categories for which the user's nearest store actually has
products.

Product List UI: Replaced the "Best Deals" horizontal list on the home_page.dart with a full "
Products Near You" grid to properly display all products available from the local store.

Permission UX: The product_upload_page.dart now proactively requests storage permission (if needed)
when the page is first loaded, improving the user experience.

🚀 0.4.0 – Profile & User Management

✨ Features

Added Profile Page UI to display user info (name, email, phone) and saved addresses.

Integrated CustomerProvider to fetch and display real user/address data
from GET /api/users/me.

Implemented Logout button with confirmation dialog: clears all user
state (CustomerProvider, LoginProvider) and navigates to LoginPage.

Added Edit Profile dialog to update user name and phone via updateUserProfile API.

Added Delete Address option with confirmation dialog (calls deleteAddress API).

Added Add New Address button (UI only, navigates to placeholder).

🛠 API & State

Created lib/api/user_api.dart for user-related API
calls (getMyProfile, addAddress, updateAddress, deleteAddress, updateUserProfile).

Updated CustomerProvider with methods to call UserApi for profile & address management.

🐞 Fixes

Fixed Null check operator crash on HomePage during app load.

Corrected userMdl.dart and addressMdl.dart with proper fromJson constructors and missing
fields (e.g., phone).

🛒 0.3.0 – Checkout & Order History

✨ Features

Added Checkout Page UI: cart summary, price details (total, discount, delivery), selected
address & payment method (static UI).

Implemented Place Order logic in CustomerProvider to call the createOrder API.

Added Order History Page UI (customer_orders_page.dart) to display a list of past orders.

Integrated CustomerProvider to fetch and display real order data from getMyOrders API.

Added "Order Placed" Success Dialog on successful checkout.

🛠 API & State

Created lib/api/order_api.dart for createOrder and getMyOrders.

Created lib/models/orderMdl.dart (CustomerOrder) with a fromJson constructor.

Updated CustomerProvider to include order state (_orders, _isLoadingOrders), error
handling, and methods (fetchMyOrders, placeOrder).

🐞 Fixes

Corrected order_api.dart to use POST for /myorders as required by the backend.

🛍 0.2.0 – Product & Cart API Integration

✨ Features

Integrated Product API: CustomerProvider now fetches real products from
getAllProducts and populates the HomePage.

Added Category List UI: "Shop by Category" section on HomePage now shows real
categories.

Added Product Details Page UI (product_detail_screen.dart) which fetches a single
product's data.

Integrated Cart API: CustomerProvider now manages a full cart state with backend
cart operations (fetch, add, update, remove, clear).

Updated CustomerProvider to use CartApi with loading/error handling and optimistic UI
updates.

Updated ProductCard → navigates to ProductDetailPage with productId.

Updated HomePage search bar → navigates to SearchPage.

📦 Models

Created lib/customer/models/cart_itemMdl.dart.

Updated productMdl.dart with fromJson constructor.

🔄 Refactor

Extracted ProductCard into a reusable widget file.

🔑 0.1.0 – Authentication & Core Setup

✨ Features

Added SplashScreen, LoginPage, and SignUpPage UIs.

Implemented dual-role toggle (Customer/Seller) on Login & Signup.

Added Name field to SignUpPage (required by backend).

Created CustomerLayout and SellerLayout with bottom navigation bars.

🛠 API & State

Created core ApiClient with support for POST, GET, PUT, DELETE, JWT storage, and
local/live URL switching.

Added lib/api/auth_api.dart for login & registration.

Created LoginProvider and SignupProvider for auth state.

Implemented role validation in LoginProvider.

⚠️ Error Handling

Added reusable ErrorDialog and SuccessDialog widgets.

Integrated dialogs into Login & Signup for user-friendly feedback.

🐞 Fixes

Implemented case-insensitive email handling in auth_api.dart.