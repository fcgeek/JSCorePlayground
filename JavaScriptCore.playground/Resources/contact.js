var createFakeContact = function() {
    var firstName = faker.name.firstName();
    var lastName = faker.name.lastName();
    var email = faker.internet.email(firstName, lastName);
    var phone = faker.phone.phoneNumber();

    var contact = createContact(firstName, lastName, email, phone);

    var script = "$('ul.contact').append('<li>FirstName: " + firstName + "</li>');";
    script += "$('ul.contact').append('<li>LastName: " + lastName + "</li>');";
    script += "$('ul.contact').append('<li>Email: " + email + "</li>');";
    script += "$('ul.contact').append('<li>Phone: " + phone + "</li>');";
    // 这段执行失败，JavaScriptCore 调试无能...
    // var drawable = new ContactDrawable();
    // drawable.firstName = firstName;
    // drawable.script = script;

    // addToView(drawable);
    return contact;
 }