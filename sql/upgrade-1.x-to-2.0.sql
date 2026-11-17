-- whip-d11-inventory 1.x -> 2.0: the bags were renamed to follow WHIP's resource prefix rule
-- (d11_bag_t1/t2/t3 -> d11_bags_t1/t2/t3, paperbag -> d11_bags_paper).
-- Stop the server first (inventories live in memory while characters are online), run this whole file on the WHIP
-- database, then start the server. Safe to run twice. A fresh install (wipe) does not need it.

START TRANSACTION;

-- 1) The item key in every slot.
UPDATE `character_inventory` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';
UPDATE `character_inventory` SET item = 'd11_bags_t2' WHERE item = 'd11_bag_t2';
UPDATE `character_inventory` SET item = 'd11_bags_t3' WHERE item = 'd11_bag_t3';
UPDATE `character_inventory` SET item = 'd11_bags_paper' WHERE item = 'paperbag';
UPDATE `container_inventory` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';
UPDATE `container_inventory` SET item = 'd11_bags_t2' WHERE item = 'd11_bag_t2';
UPDATE `container_inventory` SET item = 'd11_bags_t3' WHERE item = 'd11_bag_t3';
UPDATE `container_inventory` SET item = 'd11_bags_paper' WHERE item = 'paperbag';
UPDATE `vehicle_inventory` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';
UPDATE `vehicle_inventory` SET item = 'd11_bags_t2' WHERE item = 'd11_bag_t2';
UPDATE `vehicle_inventory` SET item = 'd11_bags_t3' WHERE item = 'd11_bag_t3';
UPDATE `vehicle_inventory` SET item = 'd11_bags_paper' WHERE item = 'paperbag';
UPDATE `ground_items` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';
UPDATE `ground_items` SET item = 'd11_bags_t2' WHERE item = 'd11_bag_t2';
UPDATE `ground_items` SET item = 'd11_bags_t3' WHERE item = 'd11_bag_t3';
UPDATE `ground_items` SET item = 'd11_bags_paper' WHERE item = 'paperbag';
UPDATE `pending_gives` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';
UPDATE `pending_gives` SET item = 'd11_bags_t2' WHERE item = 'd11_bag_t2';
UPDATE `pending_gives` SET item = 'd11_bags_t3' WHERE item = 'd11_bag_t3';
UPDATE `pending_gives` SET item = 'd11_bags_paper' WHERE item = 'paperbag';
UPDATE IGNORE `shop_item_prices` SET item = 'd11_bags_t1' WHERE item = 'd11_bag_t1';

-- 2) Items inside other items (a bag in a bag, a wallet): metadata keeps { "item": "<key>" } as JSON text.
UPDATE `character_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t1"', '"item": "d11_bags_t1"'), '"item":"d11_bag_t1"', '"item":"d11_bags_t1"') WHERE metadata LIKE '%"d11_bag_t1"%';
UPDATE `container_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t1"', '"item": "d11_bags_t1"'), '"item":"d11_bag_t1"', '"item":"d11_bags_t1"') WHERE metadata LIKE '%"d11_bag_t1"%';
UPDATE `vehicle_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t1"', '"item": "d11_bags_t1"'), '"item":"d11_bag_t1"', '"item":"d11_bags_t1"') WHERE metadata LIKE '%"d11_bag_t1"%';
UPDATE `ground_items` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t1"', '"item": "d11_bags_t1"'), '"item":"d11_bag_t1"', '"item":"d11_bags_t1"') WHERE metadata LIKE '%"d11_bag_t1"%';
UPDATE `pending_gives` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t1"', '"item": "d11_bags_t1"'), '"item":"d11_bag_t1"', '"item":"d11_bags_t1"') WHERE metadata LIKE '%"d11_bag_t1"%';
UPDATE `character_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t2"', '"item": "d11_bags_t2"'), '"item":"d11_bag_t2"', '"item":"d11_bags_t2"') WHERE metadata LIKE '%"d11_bag_t2"%';
UPDATE `container_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t2"', '"item": "d11_bags_t2"'), '"item":"d11_bag_t2"', '"item":"d11_bags_t2"') WHERE metadata LIKE '%"d11_bag_t2"%';
UPDATE `vehicle_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t2"', '"item": "d11_bags_t2"'), '"item":"d11_bag_t2"', '"item":"d11_bags_t2"') WHERE metadata LIKE '%"d11_bag_t2"%';
UPDATE `ground_items` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t2"', '"item": "d11_bags_t2"'), '"item":"d11_bag_t2"', '"item":"d11_bags_t2"') WHERE metadata LIKE '%"d11_bag_t2"%';
UPDATE `pending_gives` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t2"', '"item": "d11_bags_t2"'), '"item":"d11_bag_t2"', '"item":"d11_bags_t2"') WHERE metadata LIKE '%"d11_bag_t2"%';
UPDATE `character_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t3"', '"item": "d11_bags_t3"'), '"item":"d11_bag_t3"', '"item":"d11_bags_t3"') WHERE metadata LIKE '%"d11_bag_t3"%';
UPDATE `container_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t3"', '"item": "d11_bags_t3"'), '"item":"d11_bag_t3"', '"item":"d11_bags_t3"') WHERE metadata LIKE '%"d11_bag_t3"%';
UPDATE `vehicle_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t3"', '"item": "d11_bags_t3"'), '"item":"d11_bag_t3"', '"item":"d11_bags_t3"') WHERE metadata LIKE '%"d11_bag_t3"%';
UPDATE `ground_items` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t3"', '"item": "d11_bags_t3"'), '"item":"d11_bag_t3"', '"item":"d11_bags_t3"') WHERE metadata LIKE '%"d11_bag_t3"%';
UPDATE `pending_gives` SET metadata = REPLACE(REPLACE(metadata, '"item": "d11_bag_t3"', '"item": "d11_bags_t3"'), '"item":"d11_bag_t3"', '"item":"d11_bags_t3"') WHERE metadata LIKE '%"d11_bag_t3"%';
UPDATE `character_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "paperbag"', '"item": "d11_bags_paper"'), '"item":"paperbag"', '"item":"d11_bags_paper"') WHERE metadata LIKE '%"paperbag"%';
UPDATE `container_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "paperbag"', '"item": "d11_bags_paper"'), '"item":"paperbag"', '"item":"d11_bags_paper"') WHERE metadata LIKE '%"paperbag"%';
UPDATE `vehicle_inventory` SET metadata = REPLACE(REPLACE(metadata, '"item": "paperbag"', '"item": "d11_bags_paper"'), '"item":"paperbag"', '"item":"d11_bags_paper"') WHERE metadata LIKE '%"paperbag"%';
UPDATE `ground_items` SET metadata = REPLACE(REPLACE(metadata, '"item": "paperbag"', '"item": "d11_bags_paper"'), '"item":"paperbag"', '"item":"d11_bags_paper"') WHERE metadata LIKE '%"paperbag"%';
UPDATE `pending_gives` SET metadata = REPLACE(REPLACE(metadata, '"item": "paperbag"', '"item": "d11_bags_paper"'), '"item":"paperbag"', '"item":"d11_bags_paper"') WHERE metadata LIKE '%"paperbag"%';

COMMIT;
