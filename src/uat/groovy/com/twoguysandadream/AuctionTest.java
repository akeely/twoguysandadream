package com.twoguysandadream;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;
import org.junit.runner.RunWith;

/**
 * Created by andrewk on 2/22/15.
 */
@RunWith(Cucumber.class)
@CucumberOptions(plugin = {"pretty"}, strict = true)
public class AuctionTest {
}
