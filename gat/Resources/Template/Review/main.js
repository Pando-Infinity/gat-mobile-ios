var options = {
modules: {
toolbar: {
container: '#toolbar',
handlers: {
image: function () {
    $("#selectedImage").click();
},
clean: function () {
    let index = 0;
    let range = this.quill.getSelection();
    if (null != range && null != range.index) {
        index = range.index;
    }
    this.quill.clipboard.dangerouslyPasteHTML(
                                              index,
                                              '<br/><p class="ql-align-center"><span class="ql-size-large">...</span></p>'
                                              );
}
}
}
},
placeholder: 'What did you think of the book?',
theme: 'snow'
};
var quill = null;
var arrImageBase64 = [];
var imageBase64 = '';
var customBarHeight = 0;
const MAX_LENGTH = 175;

//  custom image
$("#selectedImage").on("change", function () {
                       const file = $("#selectedImage")[0].files[0];
                       // file type is only image and less than 1MB
                       if (/^image\//.test(file.type) && file.size / 1048576 < 10) {
                           convertImageToBase64(file);
                           } else {
                           alert("TODO - Định dạng không phù hợp hoặc dung lượng ảnh lớn hơn 10M");
                           }
                           $("#selectedImage").val('');
                           });
                       //initEditor();
                       function initEditor(placeholder) {
                       if (placeholder) {
                       options.placeholder = placeholder;
                       }
                       quill = new Quill('#editor', options);
                       quill.on('selection-change', function (range, oldRange, source) {
                                changeIconAfterSelectionChange(range);
                                });
                       quill.on('text-change', function (delta, oldDelta, source) {
                                changeIconAfterTextChange(oldDelta, delta);
                                });
                       quill.focus(true);
                       // disable editor
                       showToolbar(false);
                       }
                       
                       function setReviewContent(reviewContent) {
                       quill.clipboard.dangerouslyPasteHTML(
                                                            0,
                                                            reviewContent
                                                            );
                       }
                       
                       function getReviewContentHTML(arrImage) {
                       // Get html
                       var contentHtml = $(".ql-editor")[0].innerHTML;
                       // Replace base64 -> url
                       arrImage.forEach((element, index) => {
                                        contentHtml = contentHtml.replace(arrImageBase64[index], element);
                                        });
                       return contentHtml;
                       }
                       
                       function getReviewIntro() {
                       var contentHtml = $(".ql-editor")[0].innerHTML;
                       // console.log('test', contentHtml);
                       if (isNotNull(contentHtml)) {
                       var temp = contentHtml.replace(/<\/?[^>]+(>|$)/g, "");
                       if(temp.length > MAX_LENGTH) {
                       for(var run = MAX_LENGTH; run >= 0; run--){
                       if(" " == temp.charAt(run)) {
                       return temp.substring(0, run);
                       }
                       }
                       }
                       return temp;
                       } else {
                       return '';
                       }
                       }
                       
                       function getArrImageBase64() {
                       var arrTemp = [];
                       // Get all image in editor
                       var imageElement = $('#editor img');
                       if (imageElement) {
                       for (var i = 0; i < imageElement.length; i++) {
                       var strBase64 = $(imageElement[i]).attr('src');
                       if (-1 == strBase64.indexOf('http:') && -1 == strBase64.indexOf('https:')) {
                       arrImageBase64.push(strBase64);
                       arrTemp.push(strBase64.substring(strBase64.indexOf(",") + 1));
                       }
                       }
                       }
                       // console.log("arrImageBase64", arrTemp);
                       return arrTemp;
                       }
                       
                       function setUrlImage(imageUrl) {
                       let range = quill.getSelection();
                       quill.insertEmbed(
                                         range.index,
                                         "image",
                                         imageUrl
                                         );
                       quill.clipboard.dangerouslyPasteHTML(
                                                            range.index + 1,
                                                            '<br/><br/>'
                                                            );
                       }
                       
                       function showToolbar(isShow) {
                       if (isShow) {
                       quill.enable(true);
                       $('#custom-toolbar').show();
                       if (customBarHeight) {
                       $("#editor").css('paddingBottom', customBarHeight + 1);
                       }
                       } else {
                       quill.root.setAttribute('data-placeholder', "");
                       quill.enable(false);
                       $('#custom-toolbar').hide();
                       $("#editor").css('paddingBottom', 0);
                       }
                       }
                       
                       function resizeHtml(height, isKeyboard) {
                       if (isKeyboard) {
                       $("#editor").css('paddingBottom', height + customBarHeight + 1);
                       $("#custom-toolbar").css('paddingBottom', height);
                       } else {
                       $("#editor").css('paddingBottom', customBarHeight + 1);
                       $("#custom-toolbar").css('paddingBottom', 0);
                       }
                       }
                       
                       //==========================================================================
                       
                       function convertImageToBase64(file) {
                       // create a new FileReader to read this image and convert to base64 format
                       var reader = new FileReader();
                       // Define a callback function to run, when FileReader finishes its job
                       reader.onload = e => {
                       // Read image as base64 and set to imageData
                       setUrlImage(e.target.result);
                       }
                       // Start the reader job - read file as a data url (base64 format)
                       reader.readAsDataURL(file);
                       }
                       
                       var option = true;
                       
                       function clickSizeIcon() {
                       var element = $('#icon-text-size');
                       changeIconAfterClick(element);
                       option = !option;
                       if (option) {
                       quill.format('size', false);
                       } else {
                       quill.format('size', 'large');
                       }
                       }
                       
                       function clickListIcon() {
                       var element = $('#icon-list');
                       changeIconAfterClick(element);
                       $("button.ql-list").click()
                       }
                       
                       function clickQuoteIcon() {
                       var element = $('#icon-quote');
                       changeIconAfterClick(element);
                       $("button.ql-blockquote").click()
                       }
                       
                       function clickDivisionIcon() {
                       $("button.ql-clean").click()
                       }
                       
                       function clickImageIcon() {
                       $("button.ql-image").click()
                       }
                       
                       function changeIconAfterClick(element) {
                       var src = element.attr('src');
                       if (src.indexOf('blue') > 0) {
                       element.attr('src', src.replace('blue', 'gray'));
                       } else {
                       element.attr('src', src.replace('gray', 'blue'));
                       }
                       }
                       
                       function changeIcon(element, isBlue) {
                       var src = element.attr('src');
                       if (isBlue) {
                       element.attr('src', src.replace('gray', 'blue'));
                       } else {
                       element.attr('src', src.replace('blue', 'gray'));
                       }
                       }
                       
                       function resetIconButton() {
                       changeIcon($('#icon-text-size'), false);
                       changeIcon($('#icon-list'), false);
                       changeIcon($('#icon-quote'), false);
                       }
                       
                       function changeIconAfterSelectionChange(range) {
                       if (range) {
                       var format = quill.getFormat(range);
                       if (format) {
                       console.log("range", range);
                       console.log("format", format);
                       resetIconButton();
                       var size = format.size;
                       var list = format.list;
                       var blockquote = format.blockquote;
                       if (isNotNull(size)) {
                       changeIcon($('#icon-text-size'), true);
                       }
                       if (isNotNull(list)) {
                       changeIcon($('#icon-list'), true);
                       }
                       if (isNotNull(blockquote)) {
                       changeIcon($('#icon-quote'), true);
                       }
                       }
                       }
                       }
                       
                       function changeIconAfterTextChange(oldDelta, delta) {
                       if (oldDelta) {
                       var options = oldDelta.ops;
                       // var retain = null;
                       if (options) {
                       var latestElement = options.length;
                       //console.log("element", latestElement);
                       let attributes = latestElement.attributes;
                       let insert = latestElement.insert;
                       if (attributes) {
                       var list = attributes.list;
                       var blockquote = attributes.blockquote;
                       if (isNotNull(list)) {
                       changeIcon($('#icon-list'), true);
                       } else {
                       changeIcon($('#icon-list'), false);
                       }
                       if (isNotNull(blockquote)) {
                       changeIcon($('#icon-quote'), true);
                       } else {
                       changeIcon($('#icon-quote'), false);
                       }
                       }
                       }
                       }
                       if (delta) {
                       var options = delta.ops;
                       if (options.length == 2 && 1 == options[1].retain && isNotNull(options[1].attributes) && isNull(options[1].attributes.list)) {
                       changeIcon($('#icon-list'), false);
                       }
                       }
                       }
                       
                       function isNotNull(item) {
                       if ("undefined" == typeof (item) || null == item) {
                       return false;
                       }
                       return true;
                       }
                       
                       function isNull(item) {
                       return !isNotNull(item);
                       }
                       
                       $(document).ready(function () {
                                         customBarHeight = $("#custom-toolbar").height();
                                         if (customBarHeight) {
                                         $("#editor").css('paddingBottom', customBarHeight + 1);
                                         }
                                         });
