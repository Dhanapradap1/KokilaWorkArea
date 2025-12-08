DELIMITER $$

-- Always drop the function before recreating it
DROP FUNCTION IF EXISTS FindTableNamesByColumnName$$
--  
/*  
--  Example
select FindTableNamesByColumnName('  PLN_Q')
union 
select FindTableNamesByColumnName(' ALT_PRG_N  ')
union 
select FindTableNamesByColumnName('ALT_PRGDDSW_N')


*/
CREATE FUNCTION FindTableNamesByColumnName(target_column_name VARCHAR(255))
RETURNS VARCHAR(4096) -- Increased size to 4096 to safely hold many table names
READS SQL DATA
BEGIN
    -- Stores the list of table names found
    DECLARE v_result_tables VARCHAR(4000) DEFAULT '';
    
    DECLARE v_table_name VARCHAR(255);
    DECLARE v_column_name VARCHAR(255);
    DECLARE done INT DEFAULT 0;
      
    -- Cursor to select column and table names from the current database
    DECLARE cur_columns CURSOR FOR 
        SELECT 
            TABLE_NAME
        FROM 
            information_schema.COLUMNS
        WHERE 
            TABLE_SCHEMA = DATABASE() -- Restrict search to the current database
        AND 
            COLUMN_NAME = target_column_name or COLUMN_NAME = trim(target_column_name);
            
    -- Handler for cursor completion
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- Open the cursor (MUST be opened before FETCH)
    OPEN cur_columns;
    
    -- Loop through the results
    fetch_loop: LOOP
        -- Fetch the next row
        FETCH cur_columns INTO v_table_name;
        
        -- Exit loop if no more rows (handled by the CONTINUE HANDLER setting done = 1)
        IF done THEN
            LEAVE fetch_loop;
        END IF;
        
        -- Concatenate the found table name to the result string
        SET v_result_tables = CONCAT(v_result_tables, v_table_name, '  , ');
    END LOOP fetch_loop;
    
    -- Close the cursor (MUST be closed only once, after the loop)
    CLOSE cur_columns;
    
    -- --- Final Result Formatting ---
    
    -- Check if any tables were found
    IF v_result_tables != '' THEN
        -- Remove the trailing ', ' (2 characters) from the list
        SET v_result_tables = LEFT(v_result_tables, LENGTH(v_result_tables) - 2);
        
        -- Return format: ColumnName,TableNames,Found
        RETURN CONCAT(
            target_column_name, 
            '		-->		', 
            v_result_tables, 
            ',' 
        );
    ELSE
        -- Return format: ColumnName,,Not Found
        RETURN CONCAT(target_column_name, '*********************');
    END IF;
END$$

DELIMITER ;