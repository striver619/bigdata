package org.keynote.statistic;
/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.util.GenericOptionsParser;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.mapreduce.lib.partition.HashPartitioner;

public class UserStatic {

    public static class SortMapper
            extends Mapper<LongWritable, Text, LongWritable, Text> {

        private LongWritable sortKey = new LongWritable();
        private Text userName = new Text();

        public void map(LongWritable key, Text value, Context context
        ) throws IOException, InterruptedException {
            // skip first line and blank line
            if (key.toString().equals("0") || value.toString().equals("")) {
                return;
            }
            int sortKeyPos = Integer.parseInt(context.getConfiguration().get("sortKeyPos"));
            String[] records = value.toString().split(",");

            userName.set(records[0]);
            sortKey.set(Integer.parseInt(records[sortKeyPos]));
            // System.out.printf("sortKey is: " + sortKey + "; value is "+ value +" \n");
            context.write(sortKey, userName);
        }
    }

    public static class SortReducer
            extends Reducer<LongWritable, Text, Text, LongWritable> {

        public void reduce(LongWritable key, Iterable<Text> values,
                           Context context
        ) throws IOException, InterruptedException {
            for (Text val : values) {
                context.write(val, key);
            }
        }
    }

    public static int generate(String[] args) throws Exception {
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 3) {
            System.err.println("Usage: UserStatic <in> <out> <type>");
            System.exit(2);
        }
        conf.set("sortKeyPos", otherArgs[2]);
        Job job = Job.getInstance(conf, "UserStatic");
        job.setJarByClass(UserStatic.class);

        job.setInputFormatClass(TextInputFormat.class);
        job.setMapperClass(UserStatic.SortMapper.class);
        job.setMapOutputKeyClass(LongWritable.class);
        job.setMapOutputValueClass(Text.class);

        job.setPartitionerClass(HashPartitioner.class);
        job.setNumReduceTasks(1);
        job.setReducerClass(UserStatic.SortReducer.class);

        job.setOutputFormatClass(TextOutputFormat.class);
        FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
        FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));

        return job.waitForCompletion(true) ? 0 : 1;
    }
}
