# Spark tricks

## Deactivating output compression from hive through Spark
```
spark = SparkSession.builder \
            .config("hive.exec.dynamic.partition", "true") \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .config("hive.exec.compress.output", "false") \
            .config("spark.hadoop.mapred.output.compress", "false") \
            .enableHiveSupport().getOrCreate()
```
