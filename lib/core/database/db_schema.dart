/// Toàn bộ cấu trúc database của SMASHLY.
///
/// OWNER: TV1. Người khác KHÔNG tự sửa file này.
/// Mỗi lần đổi schema: sửa SQL bên dưới + tăng [version] + báo cả nhóm.
class DbSchema {
  DbSchema._();

  static const String dbName = 'smashly.db';

  /// Tăng số này mỗi khi đổi bảng/cột. Máy nào có version cũ sẽ tự
  /// xóa DB và tạo lại (xem DatabaseHelper.onUpgrade).
  static const int version = 2;

  // ---- Tên bảng: DAO dùng các hằng số này, không gõ chuỗi tay ----
  static const String users = 'users';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String racketSpecs = 'racket_specs';
  static const String carts = 'carts';
  static const String cartItems = 'cart_items';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String wishlists = 'wishlists';

  /// Thứ tự xóa bảng: bảng con trước, bảng cha sau.
  static const List<String> tablesInDropOrder = [
    wishlists,
    orderItems,
    orders,
    cartItems,
    carts,
    racketSpecs,
    products,
    categories,
    users,
  ];

  /// Thứ tự tạo bảng: bảng cha trước, bảng con sau.
  static const List<String> createStatements = [
    '''
    CREATE TABLE $users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name     TEXT    NOT NULL,
      email         TEXT    NOT NULL UNIQUE,
      phone         TEXT    NOT NULL,
      password_hash TEXT    NOT NULL,
      role          TEXT    NOT NULL DEFAULT 'CUSTOMER'
                    CHECK (role IN ('CUSTOMER', 'ADMIN')),
      address       TEXT,
      created_at    TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE $categories (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      name       TEXT    NOT NULL UNIQUE,
      icon_path  TEXT    NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
    ''',
    '''
    CREATE TABLE $products (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id    INTEGER NOT NULL
                     REFERENCES $categories(id) ON DELETE RESTRICT,
      name           TEXT    NOT NULL,
      brand          TEXT    NOT NULL,
      price          INTEGER NOT NULL CHECK (price > 0),
      original_price INTEGER,
      stock          INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
      rating         REAL    NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
      rating_count   INTEGER NOT NULL DEFAULT 0,
      description    TEXT    NOT NULL DEFAULT '',
      image_path     TEXT    NOT NULL,
      sizes          TEXT,
      is_featured    INTEGER NOT NULL DEFAULT 0,
      is_active      INTEGER NOT NULL DEFAULT 1,
      created_at     TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at     TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE $racketSpecs (
      product_id      INTEGER PRIMARY KEY
                      REFERENCES $products(id) ON DELETE CASCADE,
      weight_class    TEXT    NOT NULL
                      CHECK (weight_class IN ('2U', '3U', '4U', '5U')),
      balance         TEXT    NOT NULL
                      CHECK (balance IN ('HEAD_LIGHT', 'EVEN', 'HEAD_HEAVY')),
      shaft           TEXT    NOT NULL
                      CHECK (shaft IN ('FLEXIBLE', 'MEDIUM', 'STIFF', 'EXTRA_STIFF')),
      max_tension_lbs INTEGER NOT NULL,
      player_level    TEXT    NOT NULL
                      CHECK (player_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),
      play_style      TEXT    NOT NULL
                      CHECK (play_style IN ('ATTACK', 'CONTROL', 'ALL_ROUND', 'DEFENSE'))
    )
    ''',
    '''
    CREATE TABLE $carts (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL UNIQUE
                 REFERENCES $users(id) ON DELETE CASCADE,
      updated_at TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE $cartItems (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      cart_id     INTEGER NOT NULL REFERENCES $carts(id) ON DELETE CASCADE,
      product_id  INTEGER NOT NULL REFERENCES $products(id) ON DELETE CASCADE,
      quantity    INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
      size        TEXT    NOT NULL DEFAULT '',
      is_selected INTEGER NOT NULL DEFAULT 1,
      added_at    TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE (cart_id, product_id, size)
    )
    ''',
    '''
    CREATE TABLE $orders (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      order_code       TEXT    NOT NULL UNIQUE,
      user_id          INTEGER NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
      status           TEXT    NOT NULL DEFAULT 'PENDING'
                       CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED')),
      receiver_name    TEXT    NOT NULL,
      receiver_phone   TEXT    NOT NULL,
      shipping_address TEXT    NOT NULL,
      payment_method   TEXT    NOT NULL DEFAULT 'COD'
                       CHECK (payment_method IN ('COD', 'BANK_TRANSFER', 'E_WALLET')),
      note             TEXT,
      subtotal         INTEGER NOT NULL,
      shipping_fee     INTEGER NOT NULL DEFAULT 0,
      total            INTEGER NOT NULL,
      created_at       TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      confirmed_at     TEXT,
      shipped_at       TEXT,
      delivered_at     TEXT,
      cancelled_at     TEXT
    )
    ''',
    '''
    CREATE TABLE $orderItems (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id      INTEGER NOT NULL REFERENCES $orders(id) ON DELETE CASCADE,
      product_id    INTEGER REFERENCES $products(id) ON DELETE SET NULL,
      product_name  TEXT    NOT NULL,
      product_image TEXT    NOT NULL,
      unit_price    INTEGER NOT NULL,
      quantity      INTEGER NOT NULL CHECK (quantity > 0),
      size          TEXT
    )
    ''',
    '''
    CREATE TABLE $wishlists (
      user_id    INTEGER NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES $products(id) ON DELETE CASCADE,
      created_at TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, product_id)
    )
    ''',
    'CREATE INDEX idx_products_category ON $products(category_id)',
    'CREATE INDEX idx_products_brand ON $products(brand)',
    'CREATE INDEX idx_orders_user_created ON $orders(user_id, created_at)',
    'CREATE INDEX idx_cart_items_cart ON $cartItems(cart_id)',
  ];
}
