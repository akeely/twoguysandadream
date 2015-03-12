package com.twoguysandadream.resources.legacy;

import com.twoguysandadream.config.DataSourceConfiguration;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Import;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * Created by andrew_keely on 2/10/15.
 */
@Controller
@EnableAutoConfiguration
@RequestMapping("/legacy/auction")
@Import(DataSourceConfiguration.class)
public class AuctionBoard {

    @RequestMapping("/league/{league}")
    @ResponseBody
    public String checkBids(@PathVariable String league) throws IOException {

        return new String(Files.readAllBytes(Paths.get("src/main/resources/checkBids.json")));

    }

    public static void main(String[] args) throws Exception {
        SpringApplication.run(AuctionBoard.class, args);
    }
}
