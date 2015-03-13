package com.twoguysandadream.app;

import com.twoguysandadream.config.AppConfiguration;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Import;

/**
 * Created by andrewk on 3/13/15.
 */
@EnableAutoConfiguration
@Import(AppConfiguration.class)
public class Application {

    public static void main(String[] args) throws Exception {
        SpringApplication.run(Application.class, args);
    }
}
