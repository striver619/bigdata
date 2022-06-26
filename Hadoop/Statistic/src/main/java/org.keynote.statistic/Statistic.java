package org.keynote.statistic;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.util.GenericOptionsParser;
import org.apache.commons.io.FileUtils;

import java.io.File;

public class Statistic {
    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 2) {
            System.err.println("Usage: Statistic <in> <out>");
            System.exit(2);
        }
        String input = otherArgs[0];
        String output = otherArgs[1];
        if (output.startsWith("file://")) {
            FileUtils.deleteQuietly(new File(output));
        }

        // The input data format can be found at:
        // https://github.com/kunpengcompute/keynote/blob/main/data/Gitee-All-Gitee-user-detail-data-2020-10-28%2019_29_54.csv

        // Top 10 reviewers
        UserStatic.generate(new String[]{input, output+"/sort_by_review", "4"});
        // Top 10 code contributors
        UserStatic.generate(new String[]{input, output+"/sort_by_pr", "3"});
    }
}