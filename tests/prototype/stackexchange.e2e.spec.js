/**
 * @fileoverview Unit tests for the prototype.
 */

import { By, until, WebDriver } from 'selenium-webdriver';
import assert from 'assert';
import path from 'path';

const filename = 'conlang.stackexchange.com_en_all_2023-10.zim';
const filepath = path.resolve('./tests/prototype/' + filename);

const APP_HOST = new URL("http://localhost:8080/");

/**
 *  Run the tests
 * @param {WebDriver} driver Selenium WebDriver object
 * @returns {Promise<void>}  A Promise for the completion of the tests
*/
function runTests (driver) {
    let browserName, browserVersion;
    driver.getCapabilities().then(function (caps) {
        browserName = caps.get('browserName');
        browserVersion = caps.get('browserVersion');
        console.log(
          "\nRunning StackExchange tests on." +
            browserName +
            " " +
            browserVersion
        );
    });

    // Set the implicit wait to 3 seconds
    driver.manage().setTimeouts({ implicit: 3000 });

    const BUILD_FILES = ["libzim-wasm.js", "libzim-wasm.dev.js", "libzim-asm.js", "libzim-asm.dev.js"];
    BUILD_FILES.forEach(function (file) {

        describe(`Testing ${file} on ${filename}`, function () {
            this.slow(10000);
            this.timeout(20000);

            before(async function () {
                const APP_URL =
                  APP_HOST.href +
                  "tests/prototype/index.html?worker=" +
                  encodeURI(file);

                await driver.get(APP_URL);
                await driver.wait(until.elementLocated(By.id('iframeResult')));
                // await driver.executeScript(`localStorage.setItem("kiwix-libzim-wasm", "${worker}")`);
            });

            it('Load index.html and check that it is correctly loaded', async function () {
                const title = await driver.getTitle();
                assert.strictEqual(title, 'Web Worker + file api zim reader');
            });

            it('Load ' + filename + ' and check that it is correctly loaded', async function () {
                const archiveFiles = await driver.findElement(By.id('your-files'));
                await archiveFiles.sendKeys(filepath);
                var filesLength = await driver.executeScript('return document.getElementById("your-files").files.length');
                // Sleep for 2 seconds to allow libzim to initialize
                await driver.sleep(2000);
                // Check that we loaded 1 file
                assert.equal(1, filesLength);
            });

            it('Check that the ZIM contains 1139 articles', async function () {
                // Click the getArticleCount button
                const btnArticleCount = await driver.findElement(By.id('btnArticleCount'));
                await btnArticleCount.click();
                await driver.wait(until.elementLocated(By.id('articleCount')));
                const articleCount = await driver.findElement(By.id('articleCount')).getText();
                assert.equal(articleCount, '1139');
            });

            it('Load the Image "fatarrows" and check', async function () {
                const pathInput = await driver.findElement(By.id('path'));
                await pathInput.clear();
                await pathInput.sendKeys('C/Img/fatarrows.png');
                const btnGetContentByPath = await driver.findElement(By.id('btnGetContentByPath'));
                await btnGetContentByPath.click();
                // Switch to the iframe first
                await driver.switchTo().frame('iframeResult');                
                // Wait for the image to be present in the iframe
                await driver.wait(until.elementLocated(By.css('img ')), 5000);                
                // Now find the image element
                const img = await driver.findElement(By.css('img'));
                assert.ok(img);                
                // Switch back to main document
                await driver.switchTo().defaultContent();
            });

            // Click the btnCallSearch button with search field set to 'greek' and check the iframe contents contains  'questions/373/greek-based-altlangs'
            it('Search for "greek" and check the iframe contents', async function () {
                // Wait for the button to be present before clicking
                await driver.wait(until.elementLocated(By.id('btnCallSearch')), 5000);
                const btnCallSearch = await driver.findElement(By.id('btnCallSearch'));
                // Set the search field to 'greek'
                const searchField = await driver.findElement(By.id('search'));
                await searchField.clear();
                await searchField.sendKeys('greek');
                // Click the btnCallSearch button
                await btnCallSearch.click();
                await driver.sleep(1200);
                // Switch to the iframe named 'iframeResult'
                await driver.switchTo().frame('iframeResult');
                // Get the contents of the body element by CSS selector
                var body = await driver.executeScript('return document.querySelector("body").innerHTML');
                assert.ok(body.includes('questions/373/greek-based-altlangs'));
                // Switch back to main document
                await driver.switchTo().defaultContent();
            });

            // Click the btnCallSuggest button with search field already set to 'greek' and check the iframe contents contains ''
            it('Suggest for "greek" and check the iframe contents contains "A Hypothetical Mediterranean Language"', async function () {
                const btnCallSuggest = await driver.findElement(By.id('btnCallSuggest'));
                // Note that the suggest field was set to 'greek' in the previous test
                await btnCallSuggest.click();
                await driver.sleep(2000);
                // Switch to the iframe named "iframeResult"
                await driver.switchTo().frame('iframeResult');
                // Get the contents of the body element by CSS selector
                var body = await driver.executeScript('return document.querySelector("body").innerHTML');
                assert.ok(body.includes('A Hypothetical Mediterranean Language'));
                // Switch back to main document
                await driver.switchTo().defaultContent();
            });

        });
    });
    after(async function () {
        await driver.quit();
    });
}

export default {
    runTests: runTests
};
