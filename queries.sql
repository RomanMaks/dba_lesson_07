-- 1. Создайте триггеры на таблицу товаров, которые будут при создании товара, изменении 
--    его цены или удалении заполнять таблицу из пункта 2.

  -- создание нового (create)
  CREATE TRIGGER creation_product AFTER INSERT ON products
  FOR EACH ROW
    BEGIN
      INSERT INTO change_history
      SET
        product_id = NEW.id,
        event = 'create',
        new_price = NEW.price,
        affected_at = CURRENT_TIMESTAMP;
    END;

  -- изменение цены (price)
  CREATE TRIGGER changes_price BEFORE UPDATE ON products
  FOR EACH ROW
    IF (OLD.price != NEW.price) THEN
      BEGIN
        INSERT INTO change_history
        SET
          product_id = OLD.id,
          event = 'price',
          old_price = OLD.price,
          new_price = NEW.price,
          affected_at = CURRENT_TIMESTAMP;
      END;
    END IF;

  -- удаление товара (delete)
  CREATE TRIGGER deleting_product AFTER DELETE ON products
  FOR EACH ROW
    BEGIN
      INSERT INTO change_history
      SET
        product_id = OLD.id,
        event = 'delete',
        old_price = OLD.price,
        affected_at = CURRENT_TIMESTAMP;
    END;

-- 2. * Создайте функцию "размер скидки", которая по ID товара будет вычислять - сколько 
--      составило последнее изменение цены на него в процентах, используя запрос к таблице 
--      из пункта 2. Примените эту функцию в запросе на выборку товаров.  
  
  DELIMITER //
  
  CREATE FUNCTION amount_of_discount (p_id BIGINT UNSIGNED)
  RETURNS DECIMAL(5, 2)
  BEGIN
  
    DECLARE result DECIMAL(5, 2) DEFAULT NULL;
  
    SELECT IF(
        new_price < old_price,
        (old_price - new_price) / old_price * 100,
        NULL)
    INTO result
    FROM change_history
    WHERE product_id = p_id AND event = 'price'
    ORDER BY created_at DESC
    LIMIT 1;
  
    RETURN result;
  
  END;//
  
  -- Запрос на выборку товаров
  SELECT *, amount_of_discount(id) AS discount
  FROM products