/* Formatted on 8/19/2023 6:20:20 PM (QP5 v5.139.911.3011) */
set serveroutput on

DECLARE
   --to drop All SEQUENCES
   CURSOR dele_seq_cur
   IS
      SELECT SEQUENCE_NAME FROM user_sequences;

   --to create SEQUENCES and Triggers
   CURSOR seq
   IS
        SELECT DISTINCT uc.TABLE_NAME, ucc.COLUMN_NAME
          FROM user_CONSTRAINTS uc
               JOIN user_CONS_COLUMNS ucc
                  ON uc.CONSTRAINT_NAME = ucc.CONSTRAINT_NAME
               JOIN user_TAB_COLUMNS tc
                  ON tc.TABLE_NAME = uc.TABLE_NAME
                     AND tc.COLUMN_NAME = ucc.COLUMN_NAME
         WHERE     uc.CONSTRAINT_TYPE = 'P'
               AND ucc.position = 1
               AND tc.DATA_TYPE IN ('NUMBER', 'NUMERIC', 'INTEGER', 'DECIMAL') -- Adjust data types as needed
      GROUP BY uc.TABLE_NAME, ucc.COLUMN_NAME
        HAVING COUNT (DISTINCT uc.CONSTRAINT_NAME) = 1;

   v_max   NUMBER := 0;
BEGIN
   FOR seq_record IN dele_seq_cur
   LOOP
      IF seq_record.SEQUENCE_NAME IS NOT NULL
      THEN
         EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq_record.SEQUENCE_NAME;
      END IF;
   END LOOP;

   FOR record_seq IN seq
   LOOP
      EXECUTE IMMEDIATE   'SELECT MAX( '
                       || record_seq.COLUMN_NAME
                       || ' ) FROM '
                       || record_seq.TABLE_NAME
         INTO v_max;

      v_max := v_max + 1;

      EXECUTE IMMEDIATE   'CREATE SEQUENCE '
                       || record_seq.TABLE_NAME
                       || '_SEQ START WITH '
                       || v_max
                       || 'INCREMENT BY 1';


      EXECUTE IMMEDIATE   'CREATE OR REPLACE TRIGGER '
                       || record_seq.TABLE_NAME
                       || '_TRIG BEFORE INSERT ON '
                       || record_seq.TABLE_NAME
                       || ' REFERENCING NEW AS New OLD AS Old FOR EACH ROW BEGIN :new.'
                       || record_seq.column_name
                       || ' := '
                       || record_seq.TABLE_NAME
                       || '_SEQ.nextval; END;';
   END LOOP;
END;