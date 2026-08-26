# gerona_advmobprog

Lab Activity 2: The Product model defines the structure of the product data coming from the API, including things like the title, price, category, rating, stock, reviews, dimensions, and metadata. Its fromJson() method takes the raw JSON response and turns it into a proper Dart Product object that the rest of the app can work with.

The ProductService handles the actual API call, sending an HTTP GET request to fetch the product data. Once the response comes back, it decodes the JSON and maps each item into a Product object.

On the UI side, the ProductScreen uses this service along with a FutureBuilder to load the products and display them in a grid. There's also a search bar that lets users filter through the products as they type. Tapping on a product card passes that specific Product object over to the ProductDetailsScreen, which shows a more detailed view of the item.

The SettingsScreen handles theme switching through the ThemeProvider, letting users toggle the app's appearance.

Altogether, this setup follows a clean separation of concerns. The model handles data structure, the service handles fetching, and the screens handle presentation. This makes the codebase easier to read, maintain, and extend. The project also leans on the Provider pattern (via ThemeProvider) to manage theme state and notify the app whenever it changes.

In short, this activity shows how the model, service, and UI layers work together to pull data from an API and present it cleanly to the user, all while keeping responsibilities well organized.

Lab Activity 3: The cart feature builds on the same layered approach from before, adding a Model, Service, Provider, and Screen that each handle one part of the job. The Cart and CartProduct models define the shape of the cart data coming back from DummyJSON, with fromJson() converting the raw response into Dart objects the rest of the app can use.

CartService takes care of the actual API calls. getCartByUserId() fetches the cart that belongs to a specific user, addToCart() sends new items to the server, and getProductById() pulls the full product details when the cart data alone isn't enough to work with.

Sitting above the service is CartProvider, a ChangeNotifier that holds the current cart state and exposes methods like loadCart() and updateQuantity(). Whenever the cart changes, it calls notifyListeners(), which tells CartScreen to rebuild automatically without needing to manually refetch data.

On the UI side, CartScreen reads the cart from the provider and displays each product's thumbnail, price, discount, and quantity, along with a running order summary and total. Tapping a product in the cart takes its ID from the CartProduct, passes it to getProductById() to retrieve the complete product, and opens the same ProductDetailsScreen already used on the home screen, just with showAddToCart set to false since the item is already in the cart. Reusing this one screen for both flows means there's no need to build and maintain a separate details page just for cart items.

For the Cart endpoint, getCartByUserId() serves as the getById method in this activity. Rather than fetching every cart and filtering through them on the client side, it calls GET /carts/user/{userId} directly and returns only the cart that matches the current user.

Altogether, keeping the model, service, provider, and screen separate carries the same benefits from Lab Activity 2 into this one: the code stays organized, each layer is easy to reason about on its own, and the cart feature can grow without the rest of the app getting harder to follow.