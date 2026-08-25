# gerona_advmobprog

Lab Activity 2: Discussion
The Product model defines the structure of the product data coming from the API, including things like the title, price, category, rating, stock, reviews, dimensions, and metadata. Its fromJson() method takes the raw JSON response and turns it into a proper Dart Product object that the rest of the app can work with.

The ProductService handles the actual API call, sending an HTTP GET request to fetch the product data. Once the response comes back, it decodes the JSON and maps each item into a Product object.

On the UI side, the ProductScreen uses this service along with a FutureBuilder to load the products and display them in a grid. There's also a search bar that lets users filter through the products as they type. Tapping on a product card passes that specific Product object over to the ProductDetailsScreen, which shows a more detailed view of the item.

The SettingsScreen handles theme switching through the ThemeProvider, letting users toggle the app's appearance.

Altogether, this setup follows a clean separation of concerns. The model handles data structure, the service handles fetching, and the screens handle presentation. This makes the codebase easier to read, maintain, and extend. The project also leans on the Provider pattern (via ThemeProvider) to manage theme state and notify the app whenever it changes.

In short, this activity shows how the model, service, and UI layers work together to pull data from an API and present it cleanly to the user, all while keeping responsibilities well organized.