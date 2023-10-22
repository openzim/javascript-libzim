/**
 * @fileoverview Unit tests for the prototype.
 */

import { By, Key, until, WebDriver } from 'selenium-webdriver';
import assert from 'assert';
import path from 'path';


const filename = 'wikipedia_en_ray_charles_maxi_2023-09.zim';
const filepath = path.resolve('./tests/prototype/' + filename);

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
        console.log('\nRunning Legacy Ray Charles tests on: ' + browserName + ' ' + browserVersion);
    });

    // Set the implicit wait to 3 seconds
    driver.manage().setTimeouts({ implicit: 3000 });

    describe('Test the prototype', async function () {
        this.slow(10000);
        
        it('Load index.html and check that it is correctly loaded', async function () {
            await driver.get('http://localhost:8080/tests/prototype/index.html');
            await driver.wait(until.elementLocated(By.id('iframeResult')));
            const title = await driver.getTitle();
            assert.strictEqual(title, 'Web Worker + file api zim reader');
        });

        it('Load ' + filename + ' and check that it is correctly loaded', async function () {
            const archiveFiles = await driver.findElement(By.id('your-files'));
            await archiveFiles.sendKeys(filepath);
            var filesLength = await driver.executeScript('return document.getElementById("your-files").files.length');
            // Sleep for 1.5 seconds to allow libzim to initialize
            await driver.sleep(1500);
            // Check that we loaded 1 file
            assert.equal(1, filesLength);
        });

        it('Check that the ZIM contains 139 articles', async function () {
            // Click the getArticleCount button
            const btnArticleCount = await driver.findElement(By.id('btnArticleCount'));
            await btnArticleCount.click();
            await driver.wait(until.elementLocated(By.id('articleCount')));
            const articleCount = await driver.findElement(By.id('articleCount')).getText();
            assert.equal(articleCount, '139');
        });

        it('Load the article "Baby Grand" and check the title', async function () {
            // Click the btnGetContentByPath button
            const btnGetContentByPath = await driver.findElement(By.id('btnGetContentByPath'));
            await btnGetContentByPath.click();
            await driver.sleep(1200);
            // Switch to the iframe named "iframeResult"
            await driver.switchTo().frame('iframeResult');
            // Get the contents of the title element by tag name
            var title = await driver.executeScript('return document.getElementsByTagName("title")[0].innerHTML');
            console.log(title);
            assert.ok(title.includes('Baby Grand'));
        });
    });

}

export default { 
    runTests: runTests
};
