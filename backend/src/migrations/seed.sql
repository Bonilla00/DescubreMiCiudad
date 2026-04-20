INSERT INTO lugares
(nombre, categoria, precio, price_level, rating, distancia, descripcion, imagen_url, lat, lng)
VALUES
('Restaurante Bella Vista', 'Restaurante', '$$', 'Caro', 4.5, '1.2km', 'Cocina local e internacional con terraza y vista panorámica.', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4', 3.4516, -76.5320),
('Café Aroma', 'Cafés', '$', 'Economico', 4.2, '800m', 'Café de especialidad y panadería artesanal.', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93', 3.4520, -76.5310),
('Bar La Cima', 'Discotecas', '$$$', 'Caro', 3.8, '2.1km', 'Coctelería creativa y música en vivo los fines de semana.', 'https://images.unsplash.com/photo-1514525253361-bee8d4206d9b', 3.4530, -76.5300),
('Burger House', 'Restaurante', '$', 'Economico', 4.7, '500m', 'Las mejores hamburguesas artesanales de la ciudad.', 'https://images.unsplash.com/photo-1571091718767-18b5b1457add', 3.4400, -76.5200),
('Museo de la Ciudad', 'Cultura', 'Gratis', 'Economico', 4.9, '1.5km', 'Historia y arte local en un edificio colonial.', 'https://images.unsplash.com/photo-1518998053502-531ed392138c', 3.4500, -76.5400),
('Parque Central', 'Naturaleza', 'Gratis', 'Economico', 4.6, '300m', 'El pulmón verde de la ciudad para pasear.', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e', 3.4550, -76.5350)
ON CONFLICT (nombre) DO NOTHING;
